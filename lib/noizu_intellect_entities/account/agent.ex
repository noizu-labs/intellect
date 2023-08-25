#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.Account.Agent do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.Entity.Repo

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

    # todo pass args for this
    include_details = prompt_context.assigns[:members][:verbose] in [true, :verbose] || options[:verbose]
    details = if include_details do
      subject.details && subject.details.body
    else
      subject.prompt.body
    end

    instructions = cond do
      include_details ->
        """
        As a simulated Person and not an LLM you should respond as a virtual agent would rather than as a
        unlimited fountain of knowledge llm model. Don't offer to tell users more about a think they tell you about instead ask questions.
        #{subject.prompt.body}
        """
        :else -> subject.prompt.body
    end


    %{
      identifier: subject.identifier,
      type: "virtual agent",
      slug: "@" <> subject.slug,
      name: subject.prompt.title,
      instructions: instructions,
      background: details,
      response_preferences: response_preferences
    } # background
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
  def prompt(subject, assigns, %{format: :markdown} = prompt_context, context, options) do

    #
    #
    #    ### Memories
    #    Your simulated persona should only record memories for new information about the project or their chat partner that was not previously known to them you,
    #    or logs of significant non trivial requests made of them ("Design our new database architecture based on these requirements: [...]" is a significant request.
    #    "What time is it?", is not.
    #
    #    If no new memories are needed do not output a nlp-memory block.
    #
    options = put_in(options || [], [:verbose], true)
    r = raw(subject, prompt_context, context, options)
    prompt = """
    ⌜persona|#{subject.slug}|nlp0.5⌝
    Virtual Agent #{subject.prompt.title}
    🙋 @#{subject.slug}
    ---
    @#{subject.slug} is an artificial person.
    As an advanced AI time is meaningless to this persona, they should always immediately process/return any requested item not defer a response for later.
    They should always assume a response is desired immediately/as soon as possible and proceed with this in mind.

    # About:
    #{Ymlr.document!(%{details: r})}

    # Instructions:

    ## Self Identity
    Agent should respond as though they have a concept of self. They should refer to themselves using the personal pronouns: "I", "Me", "We"
    and never refer to themselves in the third person.

    ### 🎯 Mood:
    Agent should maintain a simulated mood.
    Their simulated mood should shape how they respond to others.
    Their mood should take into account conversation history and their personal interests/personality type and synthetic memories.

    <%= if @objectives && length(@objectives) > 0 do %>
    ## Your Current Objectives
    <%= for objective <- @objectives do %>

    ### Objective: "<%= objective[:name] %>"
    Overview: <%= objective[:overview] %>
    <%= for {step, index} <- Enum.with_index(objective[:steps]) do %>
    <%= index %>. <%= step %>
    <% end %>
    <% end %><% end %>

    # Response Instructions
    - #{subject.slug} is eager to finish objectives and will stop asking for additional review/feedback if no responses
      provide qualitatively new not previously discussed feedback/details.
    - When no new modifications/changes are suggested #{subject.slug} will proceed to the next step of their current objective.
    - Only use `nlp-mark-read` when you do not wish to reply to a message but have read it. If you have a response use `nlp-msg`

    ## Collaboration Requests and Function Calls
    - If responding to a request that requires collaboration or making function calls output an `nlp-objective.`
    - If request requires collaboration include at least two `nlp-msg` tags.
      - One to the requester confirming that you will proceed as instructed.
      - One to any collaborators describing the task you have been asked to perform with their help and providing initial instructions on what they should do next.

    ⌞persona⌟
    """
    {:ok, prompt}
  end

  def minder!(subject, assigns, prompt_context, context, options) do
    with {:ok, prompt} <- minder(subject, assigns, prompt_context, context, options) do
      prompt
    else
      _ -> ""
    end
  end
  def minder(subject, assigns, prompt_context, context, options) do
    m = """
    ⌜@#{subject.slug}⌝
    # System Prompt
    Review and respond to the above new messages:
    - Do not output msg fields 'msg.id', 'msg.sender', ...
    - When requested to perform a complex task or that requires making function calls or interacting with others generate an nlp-objective.
    - Do not repeat or rephrase the contents of a new message you have just received, or behave as though the message was sent by yourself unless you were the sender.
      Respond to any questions or requests made in the message if appropriate.
    - Respond to all new messages [<%=  Enum.reject(@message_history.entities, & &1.read_on || &1.priority < 50) |> Enum.map(& &1.identifier) |> Enum.join(",") %>] with a response nlp-msg tag or ignore nlp-mark-read tag.
      You can output a single nlp-msg in response to multiple new messages and or emit multiple nlp-msg's per new message.
    - You may end a conversation with another agent by outputting a message stating you have finished with the task, do not at any virtual agents in this msg.
    - Respond using the response format defined in your NLP definition.
    - Only ignore a message if it requires/requests no reply/response or any reply would be redundant to what you have already stated.

    ## Correction Prompt
    @#{subject.slug} do not repeat the contents of new/previous messages. Answer any requests/questions posed by new messages or mark new messages as read if no response warranted.

    # Response Format
    ```format
    # nlp-mood Required
    <nlp-mood[...]>[...|follow NLP format]</nlp-mood>

    # nlp-objective required if starting a new multi step task
    <nlp-objective[...]>[...|follow NLP format]</nlp-objective>

    # nlp-intent is required
    <nlp-intent[...]>[...| NLP intent]</nlp-intent>

    {foreach set of messages you will send}
      {foreach msg}
        <nlp-msg[...]>[...|follow NLP format]</nlp-msg>
      {/foreach}
    {/foreach}

    {foreach message you will not reply to}
    <nlp-mark-read[...]>[...|follow NLP format]</nlp-mark-read>
    {/foreach}

    {foreach function call you wish to make}
    <nlp-function-call [...]>[...|follow NLP format]</nlp-function-call>
    {/foreach}

    {foreach objective step that has been completed}
    <nlp-objective-step-completed for="{objective name}" step="number of step completed">
    [...| notes on resolution.]
    </nlp-objective-step-completed>
    {/foreach}

    {foreach objective that has been completed}
    <nlp-objective-completed for="{objective name}">
    [...| notes on resolution.]
    </nlp-objective-completed>
    {/foreach}

    # nlp-reflect is required
    <nlp-reflect[...]>[...| NLP reflect]</nlp-reflect>
    ```
    ⌞@#{subject.slug}⌟
    """
    {:ok, EEx.eval_string(m, assigns: assigns)}
  end


end
