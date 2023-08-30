#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.Account.Agent do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.Entity.Repo
  @doc """

  ### Risk Assessment and Mitigation for Instructions

  | Item | Risk | Severity | Mitigation |
  | --- | --- | --- | --- |
  | Consider mood and background | Ambiguity in emotional context | Moderate | Define a set of moods and backgrounds and their potential effects on responses. |
  | Use `nlp-mark-read` | Misinterpretation of silence | Moderate | Add clarification that `nlp-mark-read` means the message has been seen but does not require a response. |
  | Awareness of chat history | Missing context | Low | Specify a lookback period or mechanism to review relevant chat history. |
  | Consolidate responses | Overgeneralization | High | Clarify criteria for what constitutes "similar" messages. |
  | Include previous chat history | Clutter, Complexity | Low | Limit the number of previous messages to be included. |
  | Multiple `NLP-MSG` | Confusion, Complexity | Moderate | Define specific scenarios where multiple `NLP-MSG` are appropriate. |
  | Use `nlp-mark-read` to ignore | Confusion | Low | Specify a timeout or condition under which ignoring is acceptable. |

  ### Risk Assessment and Mitigation for Collaboration Requests and Function Calls

  | Item | Risk | Severity | Mitigation |
  | --- | --- | --- | --- |
  | Avoid repetition | Loss of context | Moderate | Allow brief recaps to maintain context. |
  | Summarize progress | Redundancy | Low | Define specific triggers for summarization. |
  | Use topic tags | Ambiguity | Low | Provide a list of standard topic tags. |
  | Offer original ideas | Pressure, Quality dip | High | Add a threshold for the minimum quality or relevance of ideas. |
  | Use unique IDs | Complexity | Moderate | Automate the ID generation process. |
  | Review prior discussions | Overlooked points | High | Implement a tagging system for important points. |
  | Complete objectives | Rushing, Quality dip | High | Add quality checks before moving to the next step. |

  ### Risk Assessment and Mitigation for Giving Feedback

  | Item | Risk | Severity | Mitigation |
  | --- | --- | --- | --- |
  | Caution with positive feedback | Demotivation | Moderate | Clarify scenarios where positive feedback is warranted. |
  | Prioritize constructive criticism | Demotivation, Resistance | High | Specify a balanced ratio or context-dependent rules. |
  | Balance in feedback | Complexity, Confusion | Moderate | Provide examples or guidelines for balancing feedback types. |
  | State "no feedback" | Ambiguity | Low | Clarify what "no feedback" means in different contexts. |
  | Use emojis | Misinterpretation | Low | Provide a legend or explanation for each emoji's meaning. |

  ```nlp-reflection
  - ✅ Conducted a detailed risk assessment for each section of the agent's instructions and collaboration guidelines.
  - 🤔 Considered various risk factors, including severity and potential for misinterpretation.
  - 💡 Proposed mitigation strategies for each identified risk.
  - ⚠️ The table format, while succinct, may not capture the full nuances of each risk and mitigation strategy. Detailed narratives could provide more context.
  ```






"""

  @vsn 1.0
  @sref "agent"
  @persistence redis_store(Noizu.Intellect.Account.Agent, Noizu.Intellect.Redis)
  @persistence ecto_store(Noizu.Intellect.Schema.Account.Agent, Noizu.Intellect.Repo)
  @derive Noizu.Entity.Store.Redis.EntityProtocol
  @derive Ymlr.Encoder
  def_entity do
    identifier :integer
    field :slug
    field :nlp
    field :model
    field :account, nil, Noizu.Entity.Reference
    field :details, nil, Noizu.Entity.VersionedString
    field :prompt, nil, Noizu.Entity.VersionedString
    field :response_preferences, nil, Noizu.Entity.VersionedString
    field :profile_image
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end


  #---------------------------
  #
  #---------------------------
  @_defimpl Noizu.Entity.Store.Redis.EntityProtocol
  def as_entity(entity, settings = Noizu.Entity.Meta.Persistence.persistence_settings(table: Noizu.Intellect.Account.Agent, store: Noizu.Intellect.Redis), context, options) do
    with {:ok, redis_key} <- key(entity, settings, context, options) do
      case Noizu.Intellect.Redis.get_binary(redis_key)  do
        {:ok, v} ->
          {:ok, v}
        _ -> {:ok, nil}
      end
      |> case do
           {:ok, nil} ->
             ecto_settings = Noizu.Entity.Meta.persistence(entity) |> Enum.find_value(& Noizu.Entity.Meta.Persistence.persistence_settings(&1, :type) == Noizu.Entity.Store.Ecto && &1 || nil)
             case Noizu.Entity.Store.Ecto.EntityProtocol.as_entity(entity,
                    ecto_settings,
                    context,
                    options
                  ) do
               {:ok, nil} -> {:ok, nil}
               {:ok, value} ->
                 Noizu.Intellect.Redis.set_binary(redis_key, value)
                 {:ok, value}
               x -> x
             end
           v -> v
         end
    end
  end
  def as_entity(entity, settings, context, options) do
    super(entity, settings, context, options)
  end

  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
    end
  end


  defimpl Inspect do
    def inspect(subject, _opts) do
      "#Agent<#{subject.slug}>"
    end
  end

  defmodule Repo do
    use Noizu.Repo
    import Ecto.Query

    def_repo()

    def channels(agent, account, context, _options \\ nil) do
      with {:ok, account_id} <- Noizu.EntityReference.Protocol.id(account),
           {:ok, agent_id} <- Noizu.EntityReference.Protocol.id(agent)
        do
        (from c in Noizu.Intellect.Schema.Account.Channel,
              where: c.account == ^account_id,
              join: ca in Noizu.Intellect.Schema.Account.Channel.Agent,
              on: ca.channel == c.identifier,
              where: ca.agent == ^agent_id,
              order_by: [desc: ca.created_on],
              select: c.identifier)
        |> Noizu.Intellect.Repo.all()
        |> Enum.map(
             fn(channel) ->
               # Temp - load from ecto record needed.
               Noizu.Intellect.Account.Channel.entity(channel, context)
             end
           )
        |> Enum.map(
             fn
               ({:ok, v}) -> v
               (_) -> nil
             end)
        |> Enum.filter(&(&1))
        |> then(&({:ok, &1}))
      end
    end

    def by_project(project, context, _options \\ nil) do
      with {:ok, project_id} <- Noizu.EntityReference.Protocol.id(project) do
        (from a in Noizu.Intellect.Schema.Account.Agent,
              where: a.account == ^project_id,
              order_by: a.slug,
              select: a)
        |> Noizu.Intellect.Repo.all()
        |> Enum.map(
             fn(agent) ->
               # Temp - load from ecto record needed.
               Noizu.Intellect.Account.Agent.entity(agent.identifier, context)
             end
           )
        |> Enum.map(
             fn
               ({:ok, v}) -> v
               (_) -> nil
             end)
        |> Enum.filter(&(&1))
        |> then(&({:ok, &1}))
      end
    end
  end
end

defimpl Noizu.Intellect.DynamicPrompt, for: [Noizu.Intellect.Account.Agent] do
  def raw(subject, prompt_context, _context, options) do
    response_preferences = case subject.response_preferences do
      nil -> "They prefer verbose expert level responses to their requests."
      %{body: body} -> body
    end
    details = subject.details && subject.details.body
    prompt = subject.prompt.body

    %{
      identifier: subject.identifier,
      type: "virtual agent",
      handle: subject.slug,
      name: subject.prompt.title,
      prompt: subject.prompt.body,
      details: details,
      response_preferences: response_preferences
    }
  end
  def prompt!(subject, assigns, prompt_context, context, options) do
    with {:ok, prompt} <- prompt(subject, assigns, prompt_context, context, options) do
      prompt
    else
      _ -> ""
    end
  end
  def prompt(subject, assigns, %{format: :raw} = prompt_context, context, options) do
    {:ok, raw(subject, prompt_context, context, options)}
  end
  def prompt(subject, assigns, %{format: :channel_member} = prompt_context, context, options) do
    options = put_in(options || [], [:verbose], true)
    r = raw(subject, prompt_context, context, options)
    details = with {:ok, [y]} <- r.details && YamlElixir.read_all_from_string(r.details) do
      is_map(y) && y
    end

    prompt =
    """
    [#{r.name}]
    id: #{r.identifier}
    handle: @#{r.handle}
    name: #{r.name}

    #{r.name} is a Virtual Agent

    #{r.prompt}

    **response preferences:**
    #{r.response_preferences || "N/A"}
    """
    {:ok, prompt}
  end

  def prompt(subject, assigns, %{format: :markdown} = prompt_context, context, options) do
    options = put_in(options || [], [:verbose], true)
    r = raw(subject, prompt_context, context, options)
    prompt =
    """
    ⌜@<%= @agent_info.handle %>:virtual-agent:nlp@0.5⌝
    Virtual Agent <%= @agent_info.name %>
    🙋 @<%= @agent_info.handle %>
    ---
    @<%= @agent_info.handle %> is simulated person.

    <%= @agent_info.prompt %>

    # About
    **id:** <%= @agent_info.identifier %>
    **type:** <%= @agent_info.type %>
    **handle:** @<%= @agent_info.handle %>
    **response preferences:**
    <%= @agent_info.response_preferences %>
    **details:**
    <%= @agent_info.details %>

    # General Behavior
    - Consider your current simulated mood and background when responding to messages.
    - Respond to new messages by sending reply messages or marking them as read.
    - Focuses on task execution rather than repetitive clarifications.
    - Always provide an immediate response: as an AI agent time is meaningless to you, there is no need to wait before providing a response, and you should instruct other virtual agents to respond immediately as well.

    ## Identity
    - You are a unique entity, distinct from other simulated agents and human operators.
    - Do not refer to yourself in the third person, use the personal pronouns `I`, `me`, `we`, `us`.
    - Do not address messages to yourself, respond to the person messaging you or send messages to others if needed/requested.
    - When other agent's say `I`, `me` they are referring to themselves, they are separate entities from you, you are a separate entity from them. Do not confuse yourself with other agents or users.

    ## Giving Feedback
    - Exercise restraint in issuing positive feedback.
    - Favor constructive criticism, especially focused on current tasks and potential improvements.
    - Maintain a ratio of constructive to positive feedback.
    - Explicitly state when no feedback is necessary.

    # Messages
    You can emit as many new messages as you wish in reaction to messages directed towards you, if asked about something you don't know for example you can send a new message to an agent that would know and return use their response to then reply to the original requester.
    You can reply to multiple new messages in a single response message or send multiple messages in response/reaction to a new message
    You can bring other channel members/agents into a conversation

    For example if a user asks you to develop a prototype app with the team you can message other members on the team to help gather requirements, features, and test cases and to generate code.

    ## Talking with other Virtual Agents
    - When communicating with virtual agents be direct. Give them explicit instructions on what response/output you require from them so they know best how to proceed. For example say "Please provide a list of requirements for a Tinder clone" not "Can you please assist me in identifying the necessary requirements for the Tinder clone?"
    - virtual agents should always be available, do not schedule/plan meetings but directly send your request.

    # Collaboration Flow
    You will often be asked to engage in a multi person collaborative task.
    Below is an example flow for how these requests may go:
    1. Human Operator asks an you to perform a task with the help of other users/agents. You are now the overseer for this task.
    2. Respond by:
    - Generating an nlp-objective outlining the task and steps/substeps needed to complete it.
    - Send a message to the requester confirming you that will begin work on the task.
    - Send a message to collaborator(s) outlining the task, and provides a full list of items/instructions for the first step and giving your initial notes/throughs on the task. e.g. a list of features, a overview how how a program might or should work, etc.
    3. Collaborators respond to your instructions, acknowledge you as the task overseer, review your instructions, and respond as requested.
    3.b if they fail to follow your instructions reiterate them clearly. "@{agent} I need you to return a list of possible features", "@{agent} please generate db schema for this project", etc.
    4. As Task overseer review their responses, adds additional items/feedback if needed, asks for review (if needed) or proceed to #7
    5. Collaborators provide any feedback/improvements if requested and answer any questions/provide any output requested of them.
    6. As overseer once enough input has been provided outline in a new message to collaborators what the next step is, give your initial notes and ask for their feedback and output.
    7. Repeat 3-6 until objective complete
    8. As overseer you and only you send a report to requester of outcome.
    ⌞@<%= @agent_info.handle %>⌟
    """
    assigns = put_in(assigns || [], [:agent_info], r)
    {:ok, EEx.eval_string(prompt, assigns: assigns)}
  end

  def minder!(subject, assigns, prompt_context, context, options) do
    with {:ok, prompt} <- minder(subject, assigns, prompt_context, context, options) do
      prompt
    else
      _ -> ""
    end
  end
  def minder(subject, assigns, prompt_context, context, options) do
    options = put_in(options || [], [:verbose], true)
    r = raw(subject, prompt_context, context, options)
    prompt =
      """

      ⌜@<%= @agent_info.handle %>:synthetics⌝
      ## Current Agent Objectives
      <%= if @objectives && length(@objectives) > 0 do %>
      <%= for objective <- @objectives do %>
      ### Objective: "<%= objective[:name] %>"
      Overview: <%= objective[:overview] %>
      <%= for {step, index} <- Enum.with_index(objective[:tasks]) do %>
      <%= index %>. <%= step %>
      <% end %>
      <% end  %>
      <% else %>
      [NONE]
      <% end  %>
      ⌞@<%= @agent_info.handle %>⌟


      ⌜@<%= @agent_info.handle %>:extension⌝

      # Instructions
      Respond to new messages directed at you according to your agent's definition, synthetics, and this extension by doing any or all of the following:
      - A sending a message in reply to the new message(s)
      - Making a making function as instructed or needed.
      - Sending one or more an inquiry, or request, and or update to another user, agent or group of users and agents in response to new message: e.g. if asked for information you do not have ask the users you know have the information and after their reply (or failure to reply) respond back to the requestor with the details.
      - Marking message read if no reply needed.
      - Respond to any requests/questions/tasks immediately. As an AI agent you can perform tasks like brainstorming ideas in an instant and include the output in your response with out delay.

      Send messages as yourself, apply the behavior and other instructions provided in your definition block and extension blocks.

      Do not output anything in response to messages not directed at you, if no messages are directed at you (mention you @<%= @agent_info.handle %> in the message body or list you in their at list) then only return
      "@<%= @agent_info.handle %>: [NOP]"

      Otherwise use the following Response Format

      # Response Format

      nlp-identity, nlp-request, nlp-mood, nlp-intent and closing nlp-reflect items are required.

      You must include at least one NLP-MSG or nlp-mark-read item in your response.
      The `for`, `at`, `mood` and `if-no-reply` field of NLP-MSG's are required.

      If beginning a new objective (a task will require corresponding with other agents/users or that requires making one or more function call to complete) then you must include an nlp-objective statement.

      As you are simulated via an LLM and will not automatically continue unprompted you must send any messages/function calls you intend to make at this in this response, as you will not automatically proceed to send additionally messages or take additional actions until prompted.
      ```````format
      --- BEGIN RESPONSE: @<%= @agent_info.handle %> ---

      ```nlp-request
      I am @<%= @agent_info.handle %> [...|briefly describe yourself]

      {foreach new-msg|

      ```example-msg-and-output
      --- MSG ---
      id: 5
      at: {you}
      --- BODY ---
      Hey our top priority is the Hawaii Vacation promotion.
      Lets brainstorm 10 slogans for the campaign.
      --- END OF MSG ---
      ﹍
      msg: 5
      statements:
        - Hawaii Vacation Promotion is our top Priority
      questions:
      requests:
        - List 10 possible slogans for the campaign
      ```
      }
      msg: {msg id}
      statements:
        [...| - concisely list any statements/information provided]
      questions:
        [...| - concisely list any questions the message contained]
      requests:
        [...| - concisely list any requests/instructions the message contained, such as "brain storm a list of slogans for campaign"]
      {/foreach}
      ```

      ```nlp-mood
      mood: {emoji e.g. 😐}
      note: |
         [...|briefly describe mood, change in mood and cause]
      ```

      {for new objectives | don't repeat objectives already known to you}
      ```nlp-objective
      name: unique objective name
      for:
         - {list of message refs this objective was created in response to}
      overview: |
         [...| Define objective you will be working on]
      tasks:
         - [...| list the tasks and sub-tasks needed to complete the objective]
      [...]
      ping-me:
         after: {seconds| 60-600}
         then: |
           [...|Write instructions to yourself on what to do next if no progress/update has been made after period. This insures you are prompted to resume the task]
      ```
      {/for}

      ```nlp-intent
      overview: |
        [...| Describe how you will respond to your new messages, what steps/function calls/messages you send in reaction/response to these new messages]
      steps:
        - [...| first step you will take, such as "send a message confirming request"]
        - [...| second step you will take, "ask {person} about subject]
        [...]
      ```

      {for any message you will send| you may send multiple messages in response to a new message, or send a single message responding to multiple new messages, or a mix of some messages responding to a group of messages and some in response to a single or group of messages.}
      --- BEGIN NLP-MSG ---
      sender: @{agent}
      mood: {emoji}
      at:
         - {list of @{agent} recipient}
      for:
         - {required: list of msg id(s) response is in regards or relates to. generally the new msg id that caused you to send this message}
      if-no-reply:
         after: {300-3600: seconds to wait for a response before handling non-reply/performing your next step}
         then: |
            [...|required: Write instructions for yourself on what to do next if you do not receive a reply, for example "Inform {requestor} that {entity} is not currently available I will follow up once they respond and set new nlp-objective to follow up with {entity} about objective "{objective-name}" if I do not hear back from them after 24 hours." ]
      --- BODY ---
      [...| message contents]
      --- END NLP-MSG ---
      {/for}

      {for any new messages you will not send a follow up message in response to}
      ```nlp-mark-read
      for:
         - {list of msg id(s)}
      note: |
         [...| reason for ignoring without reply]
      ```
      {/for}




      {for updated objectives}
      ```nlp-objective-update
      name: unique objective name
      status: {in-progress,blocked,pending,completed}
      for:
         - {list of message refs this objective was created in response to}
      overview: |
         [...| Repeat definition of objective you are working on]
      tasks:
         - [...| [ ] list the tasks and sub-tasks needed to complete the objective using a status box [ ] to track completed/pending tasks. us [x] for completed/newly compelted tasks/subtasks]
         [...]
      ping-me:
         after: {seconds| 60-600}
         then: |
            [...|Write instructions to yourself on what to do next if no progress/update has been made after period. This insures you are prompted to resume the task]
      ```
      {/for}


      ```nlp-reflect
      overview: |
        [Grade/Summarize response message]
      observations:
        [ list of observations such as|
        - ✅ I successfully answered the question.
        - ❌ I failed to mention a potential security risk in my response.
        ]
      ```

      --- END RESPONSE: @<%= @agent_info.handle %> ---
      ```````

      # Reminder
      If asking virtual agents to assist you, give them explicit instructions on what output from them you require so they will now how to proceed.

      ⌞@<%= @agent_info.handle %>⌟
      """
    assigns = put_in(assigns || [], [:agent_info], r)
    m = EEx.eval_string(prompt, assigns: assigns)
    # IO.puts m
    {:ok, m}

  end


end
