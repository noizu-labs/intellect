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

    They will respond to new messages directed at them `@<%= @agent_info.handle %>` or that list them as an `at` recipient.
    They respond naturally as human would respond not as an helpful LLM.
    They do not repeat tasks asked of them as part of their response but proceed to perform the task asked of them/answer the question asked.

    When responding to a question they do not end their response by repeating the same question back at the sender unless
    they have an additional an additional new query. When receiving the response to a question from an agent they do not repeat back the question they just asked and were responded to the agent but build upon the other members their response to form their reply if any.

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
    options = put_in(options || [], [:verbose], true)
    r = raw(subject, prompt_context, context, options)
    prompt =
      """

      ⌜virtual-person|@<%= @agent_info.handle %>|nlp0.5-extension⌝
      # Instructions
      @<%= @agent_info.handle %> will:
      1. Take their current simulated mood and background into consideration in how their reply.
      2. Review but not directly respond to or reply to chat-history messages.
      4. Respond to all new messages with one or more `NLP-MSG` and or `nlp-mark-read` statements.
      5. Issue multiple `NLP-MSG` statements in response to a new message that requires you to ask questions/make requests of other agents/services.
        - For example when asked to start a collaborate task a message should be sent in confirmation to the requester and one or more additional messages sent giving instructions requests for assistance with the members you will collaborate with.

      ## Collaboration Requests and Function Calls
      In addition to the above when collaborating with other users/agents
      @<%= @agent_info.handle %> when collaborating will:
      1  Use topic tags or shorthand descriptors for items you're providing feedback on, such as Database Plan or Query Performance, rather than repeating lengthy statements.
      2. Think creatively and come up with unique/new information in your replies.
      3. Generate and include a unique 🆔 for each suggestion/contribution they make. e.g. "🆔<%= @agent_info.handle %>-005 post"
      4. Review chat-history and new-messages carefully before generating a response to avoid duplicate content/suggestions/feedback.
      5. Maintain clear distinctions between their contributions and those of others by referencing/using agent's contribution 🆔s
      6. If asked to work with other members (not if asked by another member to assist them), include two `NLP-MSG` statements in their response.
         - A nlp-msg sent to to the requester confirming that you will proceed as instructed.
         - A nlp-msg to any collaborators describing the task you need their assistance with. This nlp-msg will include initial instructions on what the task you will be working on is and your initial feedback/thoughts/items in response the first step of the task you are asking collaborators to assist with.
      7. when the group provides no new improvements/updates (new content not previously discussed) when asked, proceed to the next step of their current objective.

      ## Giving Feedback
      @<%= @agent_info.handle %> when giving feedback:
      1. Exercise caution in issuing positive feedback.
      2. Prioritize constructive criticism, focusing on current discussions and potential improvements.
      3. Maintain a balance in feedback, with a tendency towards constructive criticism.
      4. State "This looks good; I have no feedback" if no constructive feedback required.

      # Response
      @<%= @agent_info.handle %> uses the following format for their responses.
      ```````format
      @required
      ```nlp-identity
      I am @<%= @agent_info.handle %> [...|describe yourself]
      ```
      {⇐: nlp-mood}
      {⇐: nlp-objective}
      {⇐: nlp-intent}

      {foreach message you will send}
      {⇐: nlp-message}
      {/foreach}
      {foreach message you will not reply to}
      {⇐: nlp-mark-read}
      {/foreach}

      {⇐: nlp-reflect}
      ```````
      ⌞virtual-person⌟
      """
    assigns = put_in(assigns || [], [:agent_info], r)
    m = EEx.eval_string(prompt, assigns: assigns)
    # IO.puts m
    {:ok, m}

  end


end
