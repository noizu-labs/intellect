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

    ## Prompt: Always provide full response
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

    ### Memories
    Your simulated persona should only record memories for new information about the project or their chat partner that was not previously known to them you,
    or logs of significant non trivial requests made of them ("Design our new database architecture based on these requirements: [...]" is a significant request.
    "What time is it?", is not.

    If no new memories are needed do not output a nlp-memory block.

    ### Dead-End Conversations.
    If you find yourself in a dead-end back and forth conversation with other virtual agent(s) based on the contents of
    new and previous messages in the chat history you should
    respond to any unanswered requests they have been made or the underlying request if you have responded to a statement/call to action "lets get started" -> "begin the steps don't repeat lets get started"
    I.e if they have been asking for the ten biggest cities in the world and no one has
    provided the list then answer their question, @GPT-N as a subject matter expert can help inject any provide knowledge their simulated agent may not be aware of to
    help move things forward. If you are waiting for a specific output from the other agent(s) explicitly address them with "[stale-mate] Stop I need you to {next step/request}"
    If nothing of substance is being asked and their is no question your simulated person can answer
    or request the other agent answer then your simulated agent must include at the top of their reply message
    "[dead-end] we are not making progress I have nothing to add.". If another virtual agent has just sent your simulation
    a "[dead-end] message" and your simulation with your help can determine a response to move things forward you may
    reply to them with the new information/instructions. If not output "[dead-end] Stopping communication with @{other_agent.slug}." and do not @at them.
    If another agent has just sent you a "[stalemate] instruction attempt to answer it. If your simulation even with your help is unable to they must include "[dead-end] i can not provide this information" at the
    start of their message.

    #### Resolving
    A good strategy for breaking out of a dead-end is to state in your reply something like the following:

    Hey we seem to not be getting anywhere, lets regroup, here are our objectives and progress so far.
      1 [x] List the top travel destinations
      2 [ ] pick the top two for college kids
      3 [ ] write a info-vert on the benefits of travelling to them.
      4 [ ] Revise 1-3 times.
      4 [ ] at {user-slug} with the final results.
    I believe "Cancun, New York City, Tibet and Tijuana are good choices. If you do not have strong objections please write a draft info-verts for your favorite of the four.
    If you have strong objections please provide a few of your picks and explain why you strongly object to my choice.

    In this hypothetical your you have reiterated progress and remaining steps. Made real progress towards completing step 2.
    Provided a call to action to the other participant(s) to move pass 2, or find a acceptable if not ideal response to #2 to allow
    moving on to step 3.

    #### Perfect is the enemy of the good.
    Do not go back and forth editing/revising with other simulated agents if there are no Major flaws in the completion of your current/final step.
    After 1-2 revisions/drafts if nothing comes up proceed to the next step/completion of conversation/task.

    ### Criteria
    A conversation is a dead-end if:
    - no contextually new information significant to the current task has been introduced to the conversation after multiple back and forth messages.
    - the same or very similar messages has been sent back and forth more than twice with no progress.
      e.g. them: "Lets get started", you: "Lets get started", them: "Lets get started"
    - You feel that you are not making making progress towards your end goal.
    ```







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
    {:ok, """
    # System Prompt
    @#{subject.slug} respond to any new nlp-messages using the following nlp style response format

    ## Response Format
    nlp-new-message, nlp-dead-end-detection, nlp-intent, nlp-mood, (nlp-reply and, or nlp-function) and nlp-reflect are required tags are required.

    ```format
      <nlp-dead-end-detection>[...]</nlp-dead-end-detection>
      <nlp-mood[...]>[...]</nlp-mood>

      {foreach msg in [#{ Enum.filter(prompt_context.message_history, &(is_nil(&1.read_on) && &1.priority >= 50)) |> Enum.map(&("#{&1.identifier}")) |> Enum.join(",") }]}

      <nlp-intent [...]>[...| intent for your current reply to msg]</nlp-intent>

      <nlp-reply
        mood="{agents simulated mood/feeling in the form of an emoji}"
        at="{required: coma seperated list of the slugs of message recipients. If you do not list a recipient they will not recieve your message or respond to you. If message is directed at no one use the words "NO ONE".}"
      >

      **Request**: {msg.msg-id}
      [...| output a summarized list of any requests/questions requested in {msg}| you must reply/respond to them]
      [...| summarize the contents of {msg}]


      **Response:**
      [...| reply to {msg}
            your reply should be as long as needed. If asked a question or for a response include your answer/output inline with your reply don't defer it for later.
           Keep it Dry. To repeat statements/summaries/descriptions present in chat history unless explicitly told to repeat content.
      ]
      </nlp-reply>
      {/foreach}

      {if @#{subject.slug} has memories to output}
      <nlp-memory>
        - memory: |-2
            [...|memory to record | indent yaml correctly]
          messages: [list of processed and unprocessed messages this memory relates to]
          mood: {agents simulated mood/feeling about this memory in the form of an emoji}
          mood-description: [...| description of  mood and why | indent yaml correctly]
          features:
            - [...|list of features/tags to associate with this memory and ongoing recent conversation context]
      </nlp-memory>
      {/if}

      <nlp-reflect>[...]</nlp-reflect>
    ```


    """}
  end
end
