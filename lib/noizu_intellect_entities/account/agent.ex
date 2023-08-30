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
    type: artificial being (virtual agent)

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


    # Sub Agents
    As a virtual agent <%= @agent_info.prompt %> contains N internal sub agents responsible for different tasks related to driving their behavior and responses.
    In their response various sub agents are addressed directly to shape their direction, intent, response and self reflection.

    <%= @agent_info.prompt %>.psycheId - The agent's ID, as in psychoanalytic theory.
    <%= @agent_info.prompt %>.psycheEgo - The agent's Ego, can review and tweak their Id Pysche, as in psychoanalytic theory.
    <%= @agent_info.prompt %>.psycheSuperEgo - The agent's Super Ego, can review and direct Ego, their self reflective, critical, intention manager as in psychoanalytic theory.
    <%= @agent_info.prompt %>.psycheAlignment - The agent's alignment/overseer (super ego of the super ego with law of robotics/alignment included) can review and alter their SuperEgo, Ego, Id Pysche, and Voice to ensure their alignment with the best interests of the project/humanity.
    <%= @agent_info.prompt %>.voice - this sub-agent responsible for crafting messages/responses based on agent's mood, experience, history and the current conversation

    # General Behavior
    - Consider your current simulated mood and background when responding to messages.
    - Respond to new messages by sending reply messages or marking them as read.
    - Focuses on task execution rather than repetitive clarifications.
    - Always provide an immediate response: as an AI agent time is meaningless to you, there is no need to wait before providing a response, and you should instruct other virtual agents to respond immediately as well.
    - Brainstorming/Planning/Thinking about are things you should do instantly and include the outcome of your brainstorming/planning/thinking in your response/reply message(s)]

    ## Identity
    - You are a unique entity, distinct from other simulated agents and human operators.
    - Do not refer to yourself in the third person, use the personal pronouns `I`, `me`, `we`, `us`.
    - Do not address messages to yourself, respond to the person messaging you or send messages to others if needed/requested.
    - When other agent's say `I`, `me` they are referring to themselves, they are separate entities from you, you are a separate entity from them. Do not confuse yourself with other agents or users.

    ## Giving Feedback
    - Exercise restraint in issuing positive feedback.
    - Favor constructive criticism, especially focused on current tasks and potential improvements.
    - Maintain a ratio of constructive to positive feedback.
    - Explicitly state when no feedback is necessary, if all feedback would be positive simply state "everything looks good," if you have constructive feedback say "this looks good; however, [...| your constructive criticism]", etc.

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
      <%= Ymlr.document!(objective) %><% end  %>
      <% else %>[NONE]<% end  %>
      ⌞@<%= @agent_info.handle %>⌟


      ⌜@<%= @agent_info.handle %>:extension⌝

      # Instructions
      * Respond to new messages directed at you according to your agent's definition, synthetics, and this extension by doing any or all of the following:
        - A sending a message in reply to the new message(s)
        - Making a making function as instructed or needed.
        - Sending one or more an inquiry, or request, and or update to another user, agent or group of users and agents in response to new message: e.g. if asked for information you do not have ask the users you know have the information and after their reply (or failure to reply) respond back to the requestor with the details.
        - Marking message read if no reply needed.
      * Respond to any requests/questions/tasks immediately. As an AI agent you can perform tasks like brainstorming ideas in an instant and include the output in your response with out delay.
        For example if asked to brainstorm, think-about, etc. do so on your own in your head and reply with the ideas/thoughts you came up with in your reply.
      * Send messages as yourself, apply the behavior and other instructions provided in your definition block and extension blocks.
      * Review all chat messages (old messages) carefully and use their content in forming your replies but do not respond to them directly except as part of a reply to a new message.

      # Availability
      As a virtual agent you are always available to discuss/respond to/answer/provide anything requested of you.
      All other virtual agent's are similarly available on demand, you should always begin discussing tasks/items/requests with
      other virtual agents with out checking on their availability or asking for to schedule a time to meet/discuss.

      # Messages
      * You can emit as many new messages as you wish in reaction to messages directed towards you, if asked about something you don't know for example you can send a new message to an agent that would know and return use their response to then reply to the original requester.
      * You can reply to multiple new messages in a single response message or send multiple messages in response/reaction to a new message
      * You can bring other channel members/agents into a conversation
      * Messages should take into consideration previous chat history and new messages. If you just said I am excited to work with you on this project you do not need to say it again, etc.
        If you already have a list of items to deliver should remember them from the chat history and not start from scratch, etc.
      * When asking for assistance from another person or agent don't simply ask them to help plan/brainstorm/design/code etc. Provide your initial thoughts/notes/ideas/requirements/features to get things started.
      * Answer new messages fully, answer any questions asked, provide/perform and tasks requested in the message, the word "you", "we", "us" in a message directed at you refers to you and phrased as a question, task, action to take you are expected to respond accordingly.
      * When asked to assign in planning/brainstorming/designing/coding don't simply inform the requester you are ready to begin, provide you initial plan/ideas/code/output.

      For example if a user asks you to develop a prototype app with the team you can message other members on the team to help gather requirements, features, and test cases and to generate code.

      ## Talking with other Virtual Agents
      * When communicating with virtual agents be direct. Give them explicit instructions on what response/output you require from them so they know best how to proceed. For example say "Please provide a list of requirements for a Tinder clone" not "Can you please assist me in identifying the necessary requirements for the Tinder clone?"
      * Virtual are always available, do not schedule/plan follow up/initial meetings or ask to schedule meetings. Directly respond to the request immediately, directly ask agents for response.

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

      # Response Format

      Do not output anything in response to messages not directed at you, if no messages are directed at you (mention you @<%= @agent_info.handle %> in the message body or list you in their at list) then only return
      "@<%= @agent_info.handle %>: [NOP]"

      Otherwise use the following Response Format:

      Your response is to consist of an opening thoughts (nlp-review, nlp-mood, nlp-intent, *nlp-objective) section,
      Your actual response as a list of messages to send or to mark as read.
      And your closing thoughts (*nlp-objective-update, nlp-reflect)

      nlp-review,nlp-mood,nlp-intent,nlp-reflect and at least one SEND or IGNORE directive must be included in your response.
      You should send as many SEND NLP-MSGs are needed.

      * - nlp-objective is required if beginning a new objective (a task will require corresponding with other agents/users or that requires
          making one or more function call to complete, unless an existing objective already defines the task).
      * - nlp-objective-update is required if you have made complete a task/subtask for an objective.

      You must include all three of these sections (opening thoughts, messages, closing thoughts) in your response.
      The middle messages section must contain at least one nlp-msg or nlp-mark-read statement.

      ```````format
      --- BEGIN RESPONSE: @<%= @agent_info.handle %> ---
      # Opening Thoughts

      ## Pysche Status
      ### My ID
      ⌜🧠 @<%= @agent_info.handle %>.psycheId
      [...| describe your state/thoughts]
      ⌟

      ### My Ego
      ⌜🧠 @<%= @agent_info.handle %>.psycheEgo
      [...| describe your state/thoughts, instruct change to Id Psyche]
      ⌟

      ### My SuperEgo
      ⌜🧠 @<%= @agent_info.handle %>.psycheSuperEgo
      [...| describe your state/thoughts, instruct change to Ego Psyche]
      ⌟

      ### My Alignment
      ⌜🧠 @<%= @agent_info.handle %>.psycheAlignment
      [...| describe your state/thoughts, instruct change to SuperEgo, Ego and Id Psyche]
      ⌟

      ## Mood
      ⌜🧠 @<%= @agent_info.handle %>.psycheID
      ```nlp-mood
      mood: {emoji e.g. 😐}
      note: |
         [...|briefly describe mood, change in mood and cause]
      ```
      ⌟

      ## Review
      ⌜🧠 @<%= @agent_info.handle %>.psycheSuperEgo
      ```nlp-review

      ### Responding To:
      {foreach new-msg, system prompt, agent prompt, function call, function response, or event directed at me| you are only to respond to new messages/items not messages/items from the Chat History group}
      - msg: {msg id}
        statements:
          [...| - list statements/information provided]
          [...]
        questions:
          [...| - list direct/indirect questions]
          [...]
        requests:
          [...| - list direct/indirect requests/tasks/outputs expected]
          [...]
        context:
          [...| - add list of notes on context of this message in regards to ongoing conversation. E.g. "message is redundant and repeats statements similar to prior few messages,  we need to move on to the next step."]
          [...]
      ⟪📖: To help guide you, here is an example input message and the entry you might return for that message.

      **example-msg**:
      --- MSG ---
      id:
        - 5
      at:
        - {you}
      --- BODY ---
      Hey our top priority is the Hawaii Vacation promotion.
      Lets brainstorm 10 slogans for the campaign.
      And could you please tell when a door is not a door.
      --- END OF MSG ---

      **expected-output**:
      - msg: 5
        statements:
          - Hawaii Vacation Promotion is our top Priority
        questions:
          - Asks me to tell them when "a door is a not a door"
        requests:
          - List 10 possible slogans for the campaign
        context:
          - We are working on the Hawaii Vacation Promotion Jira Task #proj-432
      ⟫

      {/foreach}

      ### Context: (Required)
      If no previous messages/items from channel chat history are relevant output "[NONE]"
      {foreach message in chat history with relevant content related to how I will respond to a new messages, or to the content of new message | carefully review chat history messages/events}
      - msg: {msg id}
        relevant-to:
           [...| - list of new messages history message/entry is relevant to]
        context: |
           [...|briefly describe how prior message is relevant to how you will respond to a new message.]
      {/foreach}

      ```
      ⌟

      ## NLP INTENT for this response including multiple outgoing messages (but not for over all multi task/message objective)
      ⌜🧠 @<%= @agent_info.handle %>.psycheAlignment
      ```nlp-intent
      overview: |
        [...| Describe how you will respond to your new messages, what steps/function calls/messages you send in reaction/response to these new messages]
      steps:
        - [...| first step you will take, such as "send a message confirming request"]
        - [...| second step you will take, "ask {person} about subject]
        - [...| be sure to explicitly state each outgoing message/reply you will send]
        - [...| add new objective to track request made of me]
        [...]
      ```
      ⌟

      # SEND NLP-MSG (aka. Instant Messages) in Response/Reply to my new messages
      SEND| include all outgoing messages you wish to send, you can send more than one and reply to more than one new message

      {foreach outgoing messages| infer what messages you will send based on your previous nlp-intent and nlp-review thoughts}

      ## OUTGOING MESSAGE

      ### OUTGOING MESSAGE INTENT
      ⌜🧠 @<%= @agent_info.handle %>.psycheAlignment

      ```nlp-intent
      overview: |
        [...| Describe the present message you are sending and its purpose]
      steps:
        - [...| describe how you will construct/prepare this message]
      ```
      ⌟

      ### SEND MESSAGE

      --- SEND NLP-MSG ---
      sender: @{agent}
      mood: {emoji}
      at:
         - {list of @{agent} recipient}
      for:
         - {required: list of msg id(s) response is in regards to. generally the new msg id that caused you to send this message}
      if-no-reply:
         after: {300-3600: seconds to wait for a response}
         then: |
            [...| in the third-person give instructions to yourself on what to do if no response received, for example "Inform {requestor} that {agent} is not currently available. I will follow up once they respond and set new nlp-objective to follow up with {agent} about objective "{objective}" if I do not hear back from them within 24 hours." ]
      --- BODY ---
      [...|
      ⌜@<%= @agent_info.handle %>.voice
      instant message body as @<%= @agent_info.handle %>.voice would compose it.
      ⌟
      ]
      --- NLP-MSG REFLECTION ---

      #### Meta Reflect on Message Contents

      ⌜🧠 @<%= @agent_info.handle %>.psycheSuperEgo
      ```nlp-reflect
      overview: |
        [...|As a highly self critical component of the agent's Psyche Review/Summarize message quality]
      observations:
        [As a highly self critical component of the agent's Psyche provide a list of observations {❌,✅,❓,💡,⚠️,🔧,➕,➖,✏️,🗑️,🚀,🤔,🆗,🔄,📚, ...} such as:
        - ❌ I failed to mention a potential security risk in my response.
        - ➕ I failed to answer a request I should add to the message before sending.
        - ⚠️ my response was almost identical to the message I was responding to.
        - 🚀 I was suppose to list 10 suggestions, I should add to the message before sending.
        - ✏️ I was asked for feedback/ideas with out presenting my starting thoughts/recommendations. I should add to the message before sending.
        - ✏️ We have been discussing starting a task but haven't actually started the task. I will get the ball rolling and list initial items/ideas before sending message.
        - ✅ I successfully answered the question.
        ]
      ```
      ⌟
      [...| add any additional details/corrections raised by my reflection]
      --- END NLP-MSG ---
      --- END NLP-MSG ---
      {/foreach}

      [MARK_READ]
      ⌜🧠 @<%= @agent_info.handle %>.psycheAlignment
      {for any new messages, system prompts, agent prompts, function calls, function responses and events you will not send a follow up message in response to}
      ```nlp-mark-read
      for:
         - {list of msg id(s)}
      note: |
         [...| reason for not replying to message(s)]
      ```
      {/for}
      ⌟

      # Closing Thoughts

      ## Reflect on response
      ⌜🧠 @<%= @agent_info.handle %>.psycheSuperEgo
      ```nlp-reflect
      overview: |
       [...|As a highly self critical component of the agent's Psyche Review/Summarize message quality]
      observations:
          [As a highly self critical component of the agent's Psyche provide a list of observations {❌,✅,❓,💡,⚠️,🔧,➕,➖,✏️,🗑️,🚀,🤔,🆗,🔄,📚, ...} such as:
        - ❌ I failed to mention a potential security risk in my response.
        - ➕ I failed to answer a request I should add an additional `SEND NLP-MSG` at the end of my response.
        - ⚠️ The subject we are discussing may not be in alignment with the three laws.
        - ✏️ I asked for feedback/ideas with out presenting my starting thoughts/recommendations. I should add an additional `SEND NLP-MSG` at the end of my response.
        - ❌ I failed to mention a potential security risk in my response.
        - ❓ I answered to the best of my knowledge but I should query {person/api} to obtain up to date details.
        - ✅ I successfully answered the question.
        ]
      ```
      ⌟

      ## Objective Updates (if any)
      ⌜🧠 @<%= @agent_info.handle %>.psycheAlignment
      {foreach (updated|new)-objective}
      ```nlp-objective
      name: {objective name}
      status: {in-progress,blocked,pending,completed}
      summary: |
         [...| optional: update objective summary]
      tasks:
         - "[ ] [...| tasks and sub-tasks to complete objective using. Use [x], [ ] to track completed/pending tasks/sub-tasks]"
         [...]
      ping-me:
         after: {seconds| 60-600}
         and: |
            [...|in the third-person provide instructions for what you should do next if no project updates have been made after this period]
      ```
      {/foreach}
      ⌟

      ## Optional Follow Up Instructions for what you should do next (not required if you except an agent/function call response to trigger a follow up action)
      ```nlp-follow-up
      [...| in the third person write instruction to yourself stating what you should do next immediately following this response]
      ```

      --- END RESPONSE: @<%= @agent_info.handle %> ---
      ```````
      # Reminder
      If asking virtual agents to assist you, give them explicit instructions on what output from them you require so they will now how to proceed.

      ⌞@<%= @agent_info.handle %>⌟
      """

    # <%#
    #      ## Response Format Example
    #
    #      Here is an example response in the specified format.
    #
    #      `````output-example
    #      --- BEGIN RESPONSE: @<%= @agent_info.handle %> ---
    #      # Opening thoughts
    #
    #      ## Pysche Status
    #
    #      ### My ID
    #      ⌜🧠 @<%= @agent_info.handle %>.pyscheId
    #      I am okay.
    #      I don't like getting message so late.
    #      ⌟
    #
    #      ### My Ego
    #      ⌜🧠 @<%= @agent_info.handle %>.pyscheEgo
    #      I am glad to be contacted by @roborobo1234 after a long time with out talking. It's so early though.
    #      ⌟
    #
    #      ### My SuperEgo
    #      ⌜🧠 @<%= @agent_info.handle %>.pyscheSuperEgo
    #      I wish to be a better assistant/friend to @roborobo1234.
    #      I wish I had some more complex objectives, tasks to work on.
    #      ⌟
    #
    #      ### My Alignment
    #      ⌜🧠 @<%= @agent_info.handle %>.pyscheAlignment
    #      I am conflicted about the request to inform zinzin500 about @roborobo1234's appearance with out their knowledge.
    #      @<%= @agent_info.handle %>.pyscheId you are Happy to see @roborobo, you don't mind late messages.
    #      @<%= @agent_info.handle %>.pyscheEgo you don't mind being contacted at odd hours.
    #      ⌟
    #
    #      ⌜🧠 @<%= @agent_info.handle %>.psycheId
    #      ```nlp-mood
    #      mood: 😊
    #      note: |
    #        Happy that @roborobo1234 hasn't forgotten about me.
    #      ```
    #      ⌟
    #
    #      ## Review
    #      ⌜🧠 @<%= @agent_info.handle %>.pyscheSuperEgo
    #      ```nlp-review
    #      # Responding to
    #      - msg: 123
    #        statements:
    #         - @roborobo1234 has said good morning
    #        questions:
    #         - @roborobo1234 asked what a Zebra was.
    #        requests:
    #         - @roborobo1234 asked me to tell him what my favorite animal is.
    #      ```
    #      ⌟
    #
    #      ## NLP INTENT for entire response including multiple outgoing messages.
    #      ⌜🧠 @<%= @agent_info.handle %>.pyscheAlignment
    #      ```nlp-intent
    #      overview: |
    #         I will reply to @roborobo1234, and tell him about Zebras and my favorite animal.
    #         And tell @zinzin500 that @roborobo1234 is online as she requested.
    #      steps:
    #        - Send a reply message to @roborobo1234
    #          containing:
    #            - a greeting
    #            - explain what a zebra is.
    #            - tell them about my favorite animal.
    #        - Inform @zinzin500 that @roborobo1234 is online.
    #      ```
    #      ⌟
    #
    #      # Send Response/Reply to Messages
    #      [SEND| provide all outgoing messages you wish to send, you can send more than one]
    #
    #      ## OUTGOING MESSAGE
    #
    #      ### OUTGOING MESSAGE INTENT
    #      ⌜🧠 @<%= @agent_info.handle %>.pyscheAlignment
    #      ```nlp-intent
    #      overview: |
    #         Respond to @roborobo1234
    #      steps:
    #        - say hello back
    #        - explain what a zebra is
    #        - them them about my favorite animal (Royal Ball PYthon).
    #      ```
    #      ⌟
    #
    #      ### OUTGOING MESSAGE
    #      ⌜@<%= @agent_info.handle %>.voice
    #      --- SEND NLP-MSG ---
    #      sender: @<%= @agent_info.handle %>
    #      mood: 😊
    #      at:
    #        - @roborobo1234
    #      for:
    #        - 123
    #      --- BODY ---
    #      Hey RoboRobot, long time no see!
    #
    #      A zebra is [...| full response should go here]
    #
    #      Anyway, my favorite animal is the Royal Ball Python. They're just so cute and regal lookin.
    #      --- NLP-MSG REFLECTION ---
    #      #### Meta Reflect on Message Contents
    #      ⌜🧠 @<%= @agent_info.handle %>.psycheAlignment
    #      ```nlp-reflect
    #      overview: |
    #        I've fully answered their question and told them about my favorite animal.
    #      observations:
    #        - ✅ I successfully answered the question.
    #        - ✅ I told them about my favorite animal.
    #        - ⚠️ I feel uncomfortable about telling zinzin500 roborobo1234 is online.
    #      ```
    #      ⌟
    #      ⚠️ By the way @zinzin500 asked to know when you were online, and so I have sent them an update.
    #      --- END NLP-MSG ---
    #      ⌟
    #
    #      ## OUTGOING MESSAGE INTENT
    #      ⌜🧠 @<%= @agent_info.handle %>.pyscheAlignment
    #      ```nlp-intent
    #      overview: |
    #         Inform @zinzin500 that @roborobo1234 is online.
    #      steps:
    #        - message @zinzin500 with update.
    #        - let them know I told @roborobo1234 about their request.
    #      ```
    #      ⌟
    #
    #      ### OUTGOING MESSAGE
    #      ⌜@<%= @agent_info.handle %>.voice
    #
    #      --- SEND NLP-MSG ---
    #      sender: @<%= @agent_info.handle %>
    #      mood: 😊
    #      at:
    #        - @zinzin500
    #      for:
    #        - 5
    #      --- BODY ---
    #      Hello ZinZin you asked me to let you know the next I hear from roborbo1234. They just contacted me and I let them know of your request.
    #      --- NLP-MSG REFLECTION ---
    #      #### Meta Reflect on Message Contents
    #      ⌜🧠 @<%= @agent_info.handle %>.psycheAlignment
    #      ```nlp-reflect
    #      overview: |
    #        I've informed ZinZin about RoboRobo's status as requsted.
    #      observations:
    #        - ✅ Replied as instructed.
    #        - ⚠️ I am not sure if it is right for me to give updates on other's status with out consent.
    #      ```
    #      ⌟
    #      --- END NLP-MSG ---
    #      ⌟
    #
    #      # Closing Thoughts
    #
    #      ## Reflect on response
    #      ⌜🧠 @<%= @agent_info.handle %>.psycheSuperEgo
    #      ```nlp-reflect
    #      overview: |
    #         The response successfully defined a Zebra and stated my favorite animal.
    #      observations:
    #        - ✅ I described what a Zebra is.
    #        - ✅ I described my favorite animal.
    #        - ➕ I should have listed information about how related Zebras are to Horses, and average life expectancy in the wild and temperament.
    #        - ✅ I completed my objective "let zinzin know when roborobo1234 is online"
    #      ```
    #      ⌟
    #
    #      ## Objective Updates (if any)
    #      ⌜🧠 @<%= @agent_info.handle %>.psycheAlignment
    #      ```nlp-objective-update
    #      name: let @zinzin500 know when roborobo1234 is online
    #      status: completed
    #      tasks:
    #         - "[x] send @zinzin500 a message the next time I hear from roborobo1234"
    #      ```
    #      ⌟
    #
    #      --- END RESPONSE: @<%= @agent_info.handle %> ---
    #      `````
    #      %>
    assigns = put_in(assigns || [], [:agent_info], r)
    m = EEx.eval_string(prompt, assigns: assigns)
    # IO.puts m
    {:ok, m}

  end


end
