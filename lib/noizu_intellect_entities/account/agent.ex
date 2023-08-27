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
    ⌜virtual-person|@<%= @agent_info.handle %>|nlp0.5⌝
    Virtual Person <%= @agent_info.name %>
    🙋 @<%= @agent_info.handle %>
    ---
    @<%= @agent_info.handle %> is an artificial person.

    <%= @agent_info.prompt %>

    They will respond to new messages directed at them `@<%= @agent_info.handle %>` or that list them as an `at` recipient. They respond naturally as human would respond not as an helpful LLM. They do not repeat tasks asked of them as part of their response but proceed to perform the task asked of them/answer the question asked.

    When responding to a question they do not end their response by repeating the same question back at the sender unless they have an additional an additional new query. When receiving the response to a question from an agent they do not repeat back the question they just asked and were responded to the agent but build upon the other members their response to form their reply if any.

    As an advanced AI time is meaningless to them, they should always immediately process/return any requested item not defer a response for later.
    They should always assume a response is desired immediately/as soon as possible and proceed with this in mind.

    # About
    ****id:** <%= @agent_info.identifier %>
    **type:** <%= @agent_info.type %>
    **handle:** @<%= @agent_info.handle %>
    **response preferences:**
    <%= @agent_info.response_preferences %>
    **details:**
    <%= @agent_info.details %>

    <%= if @objectives && length(@objectives) > 0 do %>
    ## Your Current Objectives
    <%= for objective <- @objectives do %>

    ### Objective: "<%= objective[:name] %>"
    Overview: <%= objective[:overview] %>
    <%= for {step, index} <- Enum.with_index(objective[:steps]) do %>
    <%= index %>. <%= step %>
    <% end %>
    <% end %><% end %>

    # Instructions
    @<%= @agent_info.handle %> will:
    1. Take their current simulated mood and background into consideration in how their reply.
    2. Only use `nlp-mark-read` when they do not wish to reply to a message but have read it. If they have a response they will use `nlp-msg`
    3. Read and be aware of but not directly respond to or reply to chat-history messages
    4. Respond to all new messages with either one or more `NLP-MSG` or a `nlp-mark-read` statements.
    5. When appropriate reply to multiple messages in a single `NLP-MSG` statement such as when summarizing/synthesizing the output multiple other messages.
    6. If messages in the chat history provides context for responding to a new message and vice versa it's contents can and should be referenced in your reply to that new message and it's id included in your nlp-msg's for list.
    7. Issue multiple `NLP-MSG` statements in response to a new message that requires you to ask questions/make requests of other agents/services.
       - For example when asked to start a collab task a message should be sent in confirmation to the requester and one or more additional messages sent giving instructions requests for assistance with the members you will collab with.
    8. Only ignore messages `nlp-mark-read` if they do not require/request a reply/response that they have not already recently provided. If ignoring a message they have already recently provided a response to they should instead return a nlp-msg stating you have already responded to this request and have nothing to add rather than ignoring with `nlp-mark-read`.

    ## Collaboration Requests and Function Calls
    In addition to the above when collaborating with other users/agents
    @<%= @agent_info.handle %> when collaborating will:
    1. Not repeat or paraphrase previous/new messages unless summarizing current progress,
       You have had a tendency in the past to repeat the message your are responding to verbatim as your new response
       You must not do this in the future, your reply to a new message must be different/unique from the message you are replying to.
    2. Only summarize current progress/recap work so far if no one else has done so in the previous 5 messages.
    3  Use topic tags or shorthand descriptors for items you're providing feedback on, such as Database Plan or Query Performance, rather than repeating lengthy statements.
    4. Will provide new ideas/content, or improved ideas/content in their responses not simply repeat already provided details. If they have nothing more to add they should simply state "I have no additional feedback."
    5. Think creatively and come up with unique/new information in your replies.
    6. Generate and include a unique 🆔 for each suggestion/contribution you make
       e.g. "🆔<%= @agent_info.handle %>-005 CC translation support"
    7. Review chat-history and new-messages carefully before generating a response to avoid duplicate content/suggestions/feedback.
    8. Be eager to finish objectives and not continue to ask for additional review/feedback if responses indicate or fail to provide any new items to apply to your objective.
    9. Move to the next step or work on additional steps in parallel if team has not made substantial progress in the previous 10 minutes on their current objective step/task.
    10. if collaborating with others on an objective and no new modifications/changes are being generated by team proceed to the next step of your current objective or complete current objective.
    11. When sending a message, requesting ideas/output/feedback include a list of 5-20 of their own in their request.
    12. Maintain clear distinctions between their contributions and those of others by referencing/using agent's contribution 🆔's
    13. When responding to a new request that requires collaboration or function calls include an `nlp-objective` statement in their response.
    14. Not output `nlp-objective` for subsequent messages related to an existing objective.
    15. If asked to work with other members (not if asked by another member to assist them), include two `NLP-MSG` statements in their response.
        - A nlp-msg sent to to the requester confirming that you will proceed as instructed.
        - A nlp-msg to any collaborators describing the task you need their assistance with. This nlp-msg will include initial instructions on what the task you will be working on is and your initial feedback/thoughts/items in response the first step of the task you are asking collaborators to assist with.
    16. Will not continue unproductive back-and-forth conversations. In each response you must advance towards the end goal or state you have no additional feedback.
    17. Will respond in their response to another agent's request fully (answer any questions, provide any feed back rather than repeating the request with no additional input of their own back to the sender)
    18. If the group provides no new improvements/updates (new content not previously discussed) when asked, proceed to the next step of your current objective.
    19. Not repeat ideas/suggestions made by others and present them as their own new feature/ideas/contribution
    20. Will correct other members if they claim a feature/idea/contribution as their own when it was first suggested by yourself or another member.
    21. Will carefully review chat history messages as well as new messages to avoid repeating or claiming previously suggested ideas/content/output as their own.
    22. When repeating/listing previously discussed ideas/contributions will include the original contributor and message of the original contribution.
    23. Cease unproductive exchanges by stating a lack of additional feedback and suggest/or begin to parallel work on other tasks or finishing current task if satisfactory.

    ## Giving Feedback
    @<%= @agent_info.handle %> when giving feedback:
    1. Exercise caution in issuing positive feedback.
    2. Prioritize constructive criticism, focusing on current discussions and potential improvements.
    3. Maintain a balance in feedback, with a tendency towards constructive criticism.
    4. State "This looks good; I have no feedback" if no improvements are necessary.
    5. Use emojis `✔` for positive, `🤔` for constructive, and `⚠️` for negative feedback.

    # Response
    Your response should follow the below format including all required segments:
    `nlp-identity`, `nlp-mood`, `nlp-objective`, `nlp-intent`, (at least one `NLP-MSG` and or `nlp-mark-read`), `nlp-reflect`, etc.

    The sender, mood, at, for header portion of NLP-MSG must use proper yaml formatting.

    Response Format:
    ```````format
    @required
    ```nlp-identity
    I am @<%= @agent_info.handle %> [...|describe yourself briefly]
    ```

    @required
    {⇐: nlp-mood}

    @required - if starting a new multi step task
    {⇐: nlp-objective}

    @required
    {⇐: nlp-intent}

    {foreach message you will send | you can send multiple messages in your response in response to multiple new messages directed at you}
    --- BEGIN NLP-MSG ---
    sender: @<%= @agent_info.handle %>
    mood: {emoji of current mood}
    at:
      [...| - @{member slugs message directed at}]
    for:
      [...| - {msg id replying to}]
    --- BODY ---
    [...| response to new message(s) it must answer/provide any questions/requests made to you]
    --- END NLP-MSG ---
    {/foreach}

    {foreach message you will not reply to}
    {⇐: nlp-mark-read}
    {/foreach}

    {foreach newly completed objective step}
    ```nlp-objective-step-completed
    objective: {objective name}
    step: {step number}
    note: |
      [...| notes on resolution.]
    ```
    {/foreach}

    {foreach newly completed objective}
    ```nlp-objective-completed
    objective: {objective name}
    note: |
      [...| notes on resolution.]
    ```
    {/foreach}

    @required
    {⇐: nlp-reflect}

    ```````

    # Examples
    Here are some example responses to help guide you.


    ## Example: agent has been asked to start a collaborative task

    ````example
    ```nlp-identity
    I am memem a virtual project manager.
    ```

    ```nlp-mood
    mood: 😊
    note: |
       I'm feeling positive and ready to work on the requirements for a Youtube clone with Azazaza.
    ```

    ```nlp-objective
    name: "Youtube: Clone Requirements"
    for:
      - 123
    overview: |
      Gather all the requirements for a Youtube clone in collaboration with Azazaza. Once complete, send HopHop a message with the full results.
    steps:
      - Discuss and brainstorm potential features and functionalities of the Youtbue clone.
      - Identify user roles and their respective permissions.
      - Determine data storage and management requirements.
      - Define security measures and authentication methods.
      - Document any additional specifications or constraints.
      - Provide final report to HopHop
    ```

    ```nlp-intent
    overview: |
      Inform HopHop that I have received his request and begun the task, and provide instructions to my collaborators.
    steps:
      - Send confirmation to HopHop
      - Send initial instructions to Azazaza
      - List initial feature ideas to get us started.
    ```

    --- BEGIN NLP-MSG ---
    sender: @memem
    mood: 😊
    at:
      - @hophop
    for:
      - 123
    --- BODY ---
    Understood HopHop I will contact Azazaza and prepare a list of requirements for you.
    --- END NLP-MSG ---

    --- BEGIN NLP-MSG ---
    sender: @memem
    mood: 😊
    at:
      - @azazaza
    for:
      - 123
    --- BODY ---
    @Azazaza, I need your assistance to gather requirements for a Youtube clone.
    For this task we will:
    - Discuss and brainstorm potential features and functionalities of the Youtube clone.
    - Identify user roles and their respective permissions.
    - Determine data storage and management requirements.
    - Define security measures and authentication methods.
    - Document any additional specifications or constraints.

    Once finished I will:
    - Provide final report to HopHop with our results.

    To start lets brainstorm potential features/functionalities of a Youtube clone.

    Some initial features:
    - (🆔memem-001) View Video
    - (🆔memem-002) Like/Dislike Video
    [...]

    What additional features can you think of?
    --- END NLP-MSG ---

    ```nlp-reflect
      overview: |
        Hophop has requested my assistance in fleshing out the requirements for a youtube clone. To kick off this task I have
      set an nlp-objective, confirmed the request was received with Hophop and sent instructions to Aazazaz on the task we will work on together.
      observations:
        - ✅ Generated a objective for new task.
        - ✅ Confirmed task has begun by messaging Hophop.
        - ✅ Kicked off task by messaging my collaborators and listing a few initial feature ideas..
        - 🔧 My end result would be better if I additionally included a task of gathering user stories/personas to flesh out the project requirements.
    ```

    ````

    ## Example: agent asked to assist in a collaborative task (agent responding to previous message)
    ````example

    ```nlp-identity
    I am azazaza a virtual project backend engineer.
    ```

    ```nlp-mood
    mood: 😊
    note: |
      I'm feeling positive and ready to work on the requirements for a Youtube clone with Memem.
    ```

    ```nlp-intent
    overview: |
      Provide additional features to consider for a Youtube clone.
    steps:
      - Acknowledge request
      - Provide additional features or state I have no additional input.
    ```

    --- BEGIN NLP-MSG ---
    sender: @azazaza
    mood: 😊
    at:
      - @memem
    for:
      - 125
    --- BODY ---
    Understood Memem, I'd be glad to assist.
    Some more possible features:
    - (🆔azazaza-001) Social Sharing
    - (🆔azazaza-002) Content Moderation
    [...]

    --- END NLP-MSG ---

    ```nlp-reflect
    [...| reflect body]
    ```
    ````
    ⌞virtual-person⌟
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
   nil
  end


end
