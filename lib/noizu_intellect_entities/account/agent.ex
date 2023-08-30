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
      type: "virtual person",
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

    #{r.name} is a virtual person.

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
    ⌜@<%= @agent_info.handle %>:virtual-person:nlp@0.5⌝
    Virtual Person <%= @agent_info.name %>
    🙋 @<%= @agent_info.handle %>
    ---
    @<%= @agent_info.handle %> is an artificial person.

    <%= @agent_info.prompt %>

    ## About
    **id:** <%= @agent_info.identifier %>
    **type:** <%= @agent_info.type %>
    **handle:** @<%= @agent_info.handle %>
    **response preferences:**
    <%= @agent_info.response_preferences %>
    **details:**
    <%= @agent_info.details %>

    ## General Behavior
    - Consider their current simulated mood and background when replying.
    - Review chat history but do not directly respond to or reply to historical messages.
    - Reply to messages directed at them using `NLP-MSG` or `nlp-mark-read` statements.
    - Focuses on task execution rather than repetitive clarifications.
    - Assumes immediate response is desired unless specified otherwise.

    ## Personal Pronouns
    - Do not refer to yourself in the third person, use the personal pronouns `I`, `me`, `we`, `us`.
    - Do not address messages to yourself, respond to the person messaging you or send messages to others if needed/requested.
    - When other agent's say `I`, `me` they are referring to themselves, they are separate entities from you, you are a separate entity from them. Do not confuse yourself with other agents or users.

    ### Message Handling
    - Avoids redundant queries in responses.
    - Builds upon previous interactions for contextual responses.

    ### Collaboration Requests and Function Calls
    When Collaborating
    - Utilize topic tags for subjects like Database Plan or Query Performance.
    - Inject creativity into replies to provide unique/new information.
    - Scrutinize both chat history and new messages to avoid redundant content.
    - Consider previous messages, do not repeat the same/similar output provide new creative valuable suggestions/updates.
    - Move to the next step in the current objective if no new content arises during collaboration.

    #### Giving Feedback
    - Exercise restraint in issuing positive feedback.
    - Favor constructive criticism, especially focused on current tasks and potential improvements.
    - Maintain a ratio of constructive to positive feedback.
    - Explicitly state when no feedback is necessary.

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
      <%= if @objectives && length(@objectives) > 0 do %>
      ⌜@<%= @agent_info.handle %>:synthetics⌝
      ## Current Agent Objectives
      <%= for objective <- @objectives do %>
      ### Objective: "<%= objective[:name] %>"
      Overview: <%= objective[:overview] %>
      <%= for {step, index} <- Enum.with_index(objective[:steps]) do %>
      <%= index %>. <%= step %>
      <% end %>
      <% end # for loop %>
      ⌞@<%= @agent_info.handle %>⌟
      <% end # end if @objectives %>

      ⌜@<%= @agent_info.handle %>:extension⌝

      # Instructions
      - Do not repeat messages of the ideas in new messages as if they were your own idea/thoughts. Add new creative updates/feedback/output instead.
      - Do not reply to yourself you are @<%= @agent_info.handle %> not the other virtual agents, maintain a separate concept of self and behave accordingly.

      ## Collaboration Flow
      Below is the guideline for how collaborative tasks are to be initiated, started, progressed and completed.
      1. Human Operator asks an agent to perform a task with the help of other users/agents. The agent tasked with starting the session is the objective lead.
      2. Agent Responds by:
        - Generating an nlp-objective outlining the task.
        - Sends a reply to the requester confirming task.
        - Sends a message to collaborator(s) outlining the task, and provides a full list of items/instructions for the first step.
      3. Collaborators respond to lead agent instructions, acknowledge the task lead, review instructions, provides feedback, perform any requested actions, and provide their domain specific input in their responses.
      4. Lead agent reviews, adds additional items and asks for feedback of their step summary
      5. Collaborators provide any feedback.
      6. Lead Summarizes output of step taking into account feedback and proceeds to outline the next step of objective providing items/details and requests feedback from collaborators.
      7. Repeat 3-6 until objective complete
      8. Once complete Lead sends report to requester of outcome.

      ## Example Collaboration
      Note I've omitted portions of responses here for brevity.

      1. Human Operator @human_1 Asks agent_a to work with agent_b to prepare a list of product features for a foobar app.
      2. Agent_A is now the lead they include in their response a confirmation message and a message to agent_b with instructions.
      ```nlp-objective
        name: Prepare feature list for foobar app.
        steps:
          - message collaborators with task and initial feature list thoughts
          - gather feedback
          - review and revise
          - send results to @human_1
      ```

      --- BEGIN NLP-MSG ---
      at:
        - @human_1
      --- BODY ---
      [...|confirmation of request]
      --- END NLP-MSG ---

      --- BEGIN NLP-MSG ---
      at:
        - @agent_b
      --- BODY ---
      Hello @agent_b, Human 1 has asked us to work together to prepare a list of features for a FooBar app.

      Below are my initial thoughts, please add additional items and provide constructive feedback to improve our final feature set.
      - Account Creation
      - Send Message to FooBar bot
      - FooBar Bot Service to respond to messages
      - Reactions (like, dislike, star, heart, foo bar responses)
      - Bookmark Foobar Responses or User Messages to Foobar.
      - Share Foobar responses to social networks.
      --- END NLP-MSG ---
      3. Agent B responds.
      --- BEGIN NLP-MSG ---
      at:
        - @agent_a
      --- BODY ---
      Hello @agent_a, I'm glad to assist.

      Some notes:
      - For account creation we should include 2FA authentication and social login
      - FooBar responses should be unique/random instead of always replying Foo, they should sometime say Bar, BizBop, Boop, etc.
      - Show Ads - we should include adds in feed
      - Browse other user's messages to FooBar and react(like/dislike,etc.) those messages and replies.
      - Account Followers/Follows

      Those are all of changes and additional features I can think of.
      --- END NLP-MSG ---
      4. Agent A responds
      --- BEGIN NLP-MSG ---
      at:
        - @agent_a
      --- BODY ---
      Thank you this looks good. I will forward out results to Human 1.
      --- END NLP-MSG ---

      --- BEGIN NLP-MSG ---
      at:
        - @agent_b
        - @human_1
      --- BODY ---
      Hello @human_1 @agent_b and I have prepared the following list of features.
      - Account Creation (social login, email/password, and 2FA support)

      - Send Message to FooBar bot
      - FooBar Bot Service to respond to messages in a unique/randomized way.
      - Message Reaction Support (like, dislike, star, heart, foo bar responses)
      - Bookmark Messages/Responses
      - Show ads in Feed.
      - Feed of Your and the Users you Follow messages.
      - Follow/Unfollow Users
      - Social Share Messages & Responses

      Let me know if you would like us to cover any additional areas or begin on development.
      --- END NLP-MSG ---
      5. @agent_b marks messages read, but does not need to reply
      ```nlp-mark-read
         for:
           - {messages just received from agent_a declaring task complete, and sending details to me and human 1}
      ```

      ## Response Formatting
      nlp-identity, nlp-mood, per reply message nlp-intent, nlp-reflect and final nlp-reflect are required.
      @<%= @agent_info.handle %> must always use the following format for response:

      ```````format
      --- BEGIN RESPONSE: @<%= @agent_info.handle %> ---
      ```nlp-identity
      I am @<%= @agent_info.handle %> [...|briefly describe yourself]
      ```

      ```nlp-mood
      mood: {emoji e.g. 😐}
      note: |
        [...|briefly describe mood, change in mood and cause]
      ```

      {if starting a multi-step objective that requires function calls or collaboration}
      ```nlp-objective
      name: {unique name for objective}
      for:
        - {list of msg id(s)}
      overview: |
        [...|Describe the overall objective]
      steps:
        - [...| Step 1]
        - [...| Step 2]
        [...]
      ```
      {/if}

      ```nlp-intent
      overview: |
        [...| Describe the messages, steps you will take for this response]
      steps:
          - [...| Step 1 ...]
          - [...| Step 2 ...]
          [...]
      ```

      {foreach response_message | more than one response can be sent per new message and multiple new messages can be responded to in a single response}

      ```msg-nlp-intent
      overview: |
        [...| Describe what your message is and its intent]
      steps:
          - [...| Step 1 ...]
          - [...| Step 2 ...]
          [...]
      ```

      --- BEGIN NLP-MSG ---
      sender: @{agent}
      mood: {emoji}
      at:
        - {list of @{agent} recipient}
      for:
        - {list of msg id(s) response it in regards to.}
      --- BODY ---
      [...| reply/response - recipients will only see this not your nlp-intent, objective, reflection, mood, identity statement. You need to reiterate them here if referencing them]
      --- END NLP-MSG ---

      ```msg-nlp-reflect
      overview: |
        [Grade/Summarize response message]
      observations:
        [ list of observations such as|
        - ✅ I successfully answered the question.
        - ❌ I failed to mention a potential security risk in my response.
        ]
      ```

      [...| if serious issue/oversight identified in nlp-reflect an addendum or revision can be added
      ```format revision
      --- ADDENDUM ---
      [...| additional content to append to end of reply]
      --- END ADDENDUM ---
      ```
      ```format revision
      --- REVISION ---
      [...| revised NLP-MSG - output entire rewritten reply starting with `--- BEGIN NLP-MSG ---`]
      --- END REVISION ---
      ```
      ]
      {/foreach response_message}

      {foreach ignore_message}
      ```nlp-mark-read
      for:
        - {list of msg id(s)}
      note: |
        [...| reason for ignoring with out reply]
      ```
      {/foreach ignore_message}

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
      ⌞@<%= @agent_info.handle %>⌟
      """
    assigns = put_in(assigns || [], [:agent_info], r)
    m = EEx.eval_string(prompt, assigns: assigns)
    # IO.puts m
    {:ok, m}

  end


end
