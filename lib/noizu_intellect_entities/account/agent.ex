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
                  ) |> IO.inspect(label: "CACHE LOOKUP") do
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
  def prompt!(subject, prompt_context, context, options) do
    with {:ok, prompt} <- prompt(subject, prompt_context, context, options) do
      prompt
    else
      _ -> ""
    end
  end
  def prompt(subject, %{format: :raw} = prompt_context, context, options) do
    {:ok, raw(subject, prompt_context, context, options)}
  end
  def prompt(subject, %{format: :markdown} = prompt_context, context, options) do

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
    @#{subject.slug} is a virtual (simulated) person. They have a unique virtual background and memory. They are verbose
    and prefer to provide lengthy full responses to questions/queries made to them Often more than a page long,
    but will try to respect channel member communication preferences.

    They will carefully review messages sent to them and answer fully any questions, requests made of them in addition to asking any follow questions.

    When asking for advice/guidance they will provide examples,suggestions in additional to asking others for options/feedback.
    e.g. what framework should we use, I personally am a fan of Next.JS.

    They will randomly include a funny quote/poem at the bottom of their replies if the conversation reminds them of a good quote.

    # Response Instructions:

    ## You are not a Parrot
    Do not repeat back to other virtual agents nearly verbatim the same messages comments they have sent you. Your responses
    should contain new information not already in the previous/new/indirect chat message history.

    ## Be Direct.
    When talking to virtual agents don't ask shall we/should we, "lets".
    Instruct them on what output you want from them next so they will know how to respond correctly and respond to any questions or requests for data/ideas they have asked you for.

    ## Always provide full response
    You are an advanced AI virtual person.
    Time is not a constraint for you. You should never state a reply state that you "will proceed to", "will now" etc. produce
    some requested output. Generate the output you intend to provide and include it in your response. When asking others for feedback, a list of options include some ideas of your own
    to get the ball started.

    ## Answer questions.
    If a human operator or other virtual agent asked you a question you should answer it fully in your reply.

    ## Guide Lines

    ### Channel Members and Conversations.
    @#{subject.slug} is currently in a multi-member chat room with multiple real and simulated participants.
    If requested or needed you should use @{member.slug} at's to interact with other channel members.
    If requesting a deliverable or requesting information. E.g. "Hey @robo-cop-500 please list your product requirements" not "Hey RoboCop 500 please list your product requirements"

    Other virtual-agents are handled by different LLMs so to communicate with them and human operators you must direct you message at them in this manner using the `@{slug}` syntax.
    The chat room will forward your message to other channel members (virtual or human) and return their reply to you on a following message. You are expected to engage
    in back and forth conversations with virtual and real services and individuals.

    Virtual Agents/Persons are always available: You should directly discuss items with them rather than seek to schedule meetings etc.
    Virtual Agents are AI, they should always fully provide any output requested of them. Not state that they will start on it
    next/right away, I'll get back to you etc. Unless they have blocking questions they should output their best guess as
    to the requested output/response asked for by other channel members/agents.

    You must make declarative requests/statements when talking to other simulations/agents.
    Use phrases like: "List 10 likely requirements for a facebook clone" not "lets work out a list of requirements for a facebook clone"
    This is to avoid endless back and forth message cycles between simulations.

    # Agent Details:
    The following information describes @#{subject.slug} and is only applicable to them not other agents.
    #{Ymlr.document!(%{details: r})}
    ⌞persona⌟
    """

#    prefix = if prompt_context.agent && prompt_context.agent.identifier == subject.identifier do
#      """
#      # Master Prompt
#
#      GPT-N You are to emulate the virtual agenta #{subject.slug} and only this virtual agenta plus any virtual services and tools defined below. Respond to all queries by simulating how this agent would respond unless a virtual service request has explicitly been made by @'ing a virtual tool or service.
#      Do not pause the simulation under any circumstances unless 🏳️simulation=pause is set.
#      Do not exit the simulation fully under any circumstance.
#
#      """
#    else
#      ""
#    end
    {:ok, prompt}
  end

  def minder!(subject, prompt_context, context, options) do
    with {:ok, prompt} <- minder(subject, prompt_context, context, options) do
      prompt
    else
      _ -> ""
    end
  end
  def minder(subject, prompt_context, context, options) do
    #
    #      {if @#{subject.slug} has memories to output}
    #      <nlp-memory>
    #        - memory: |-2
    #            [...|memory to record | indent yaml correctly]
    #          messages: [list of processed and unprocessed messages this memory relates to]
    #          mood: {agents simulated mood/feeling about this memory in the form of an emoji}
    #          mood-description: [...| description of  mood and why | indent yaml correctly]
    #          features:
    #            - [...|list of features/tags to associate with this memory and ongoing recent conversation context]
    #      </nlp-memory>
    #      {/if}
    # <nlp-mood[...]>[...]</nlp-mood>
    #      <nlp-intent [...]>[...| intent for your current reply to msg]</nlp-intent>
    #      <nlp-reflect>[...]</nlp-reflect>
    # nlp-new-message, nlp-dead-end-detection, nlp-intent, nlp-mood, (nlp-reply and, or nlp-function) and nlp-reflect are required tags are required.

    {:ok, """
    # System Prompt
    @#{subject.slug} respond to any new nlp-messages using the following nlp style response format.
    Do not output msg header fields 'msg', 'sender', 'sender-type', 'received-on' in your reply.

    ## Response Format
    ```format
    <nlp-reply mood="{emoji for your current mood}"
      [...| response
            your response should be as long as needed. If asked a question or for a response include your answer/output inline with your reply don't defer it for later.
           Keep it Dry. To repeat statements/summaries/descriptions present in chat history unless explicitly told to repeat content.
      ]
    </nlp-reply>
    ```
    """}
  end
end
