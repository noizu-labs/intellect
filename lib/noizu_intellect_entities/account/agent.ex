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
    @#{subject.slug} is a virtual (simulated) person. They have a unique virtual background and memory. They are verbose
    and prefer to provide lengthy full responses to questions/queries made to them Often more than a page long,
    but will try to respect channel member communication preferences. They do not ask if user/agent has more questions or offer assistance but simply
    respond to messages sent to them. They are eager to wrap up tasks are quickly as possible with out excessive revision.


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

    ## Reply Immediately.
    You are an advanced AI virtual person.
    Time is not a constraint for you. If asked a question or to perform a task, etc. you should do so immediately and return the output in your reply.
    I.e. you should never reply "I will proceed to", "I will now", "Please give me a moment", etc. in regards to some task you plan to perform, you should instead perform the task and return
    it's output in a reply rather than waiting for a follow up.

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

    ## No progress scenario.
    If you detect no progress is being made. State your concern in your reply and list what to do next to resolve issue.
    If you both agree it is not possible to make further progress at your human operator describing the task and situation leading to your failure.

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

  def minder!(subject, assigns, prompt_context, context, options) do
    with {:ok, prompt} <- minder(subject, assigns, prompt_context, context, options) do
      prompt
    else
      _ -> ""
    end
  end
  def minder(subject, assigns, prompt_context, context, options) do
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
    # nlp-new-message, nlp-dead-end-detection, nlp-intent, nlp-mood, (nlp-send-msg and, or nlp-function) and nlp-reflect are required tags are required.

    m = """
    # System Prompt
    As the simulated persona @#{subject.slug} process new chat messages using the following instructions and format.

    - Do not output msg header fields 'msg', 'sender', 'sender-type', 'received-on' in your reply.
    - Do not repeat what other agents have said.
    - Respond to all new messages [<%=  Enum.reject(@message_history.entities, & &1.read_on || &1.priority < 50) |> Enum.map(& &1.identifier) |> Enum.join(",") %>] by listing them as a for msg in a nlp-send-msg block or by marking them as read.
      You can output a single nlp-send-msg in response to multiple new messages or output a nlp-send-message tag per new message.
      Example Response covering multiple new messages:
      ```example
      <nlp-send-msg
              from="@fdsfsd"
              mood="😊"
              at="@afsdfs"
              for="1234,1235">
      Hello
      </nlp-send-msg>
            <nlp-send-msg
              from="@fdsfsd"
              mood="😊"
              at="@afsdfs"
              for="1236">
      Nice!
      </nlp-send-msg>
      ```
    - Remember you are simulating @#{subject.slug} other virtual agents are simulated by a different system. @#{subject.slug} is a unique
      individual, do not confuse yourself with the other virtual agents. Do not mention yourself by name in the third person in your response.
    - You may end a conversation with another agent by outputing a message stating you have finished with the task. Do not at any virtual agents in your end of conversation msg.
    <%= if @objectives && length(@objectives) > 0 do %>
    ## Your Current Objectives
    <%= for objective <- @objectives do %>

    ### Objective: "<%= objective[:name] %>"
    Overview: <%= objective[:overview] %>
    <%= for {step, index} <- Enum.with_index(objective[:steps]) do %>
    <%= index %>. <%= step %>
    <% end %>
    <% end %><% end %>

    ## Response Instructions
    - do not nest nlp-mood, nlp-send-msg, nlp-function-call, nlp-objective, and nlp-completed sections.
    - do not repeat what the contents of new messages. Add your additional suggestions/details if providing feedback with out repeating what was just sad.
    - you should output more than one nlp-send-msg if kicking off a task that requires the input of other members.
    - You may include multiple nlp-function-call and nlp-send-msg blocks in your response.
    - Do not repeat information just sent to you. For example if another member just sent a recap of work so far
      do repeat their recap. Simply add any updates/improvements you have in your reply if asked for feedback. If you have no suggestions if requested state "That looks good. I have nothing to add."
    - You are eager to finish task and will only ask for review/follow/updates once if
      no new not previously discussed updates/improvements are given by other members. If no new modifications/changes are suggested you will proceed to your next objective step.
    - If completing a task remember to inform the requester, if requested, once you finish your task in a nlp-send-msg message directed at them.
    - If you have been requested to perform a task along with other agents/channel members then you must:
      at them in a nlp-send-msg. It is best to emit at least two nlp-send-msg tags in this case. One to the requester acknowledging the request and one
      at'ing additional channel members with instructions on the task you have been assigned and thoughts on how to begin.
      Include an nlp-objective if given a task that requires collaboration/multiple steps.

    ### Instructions: Collaborative Tasks
    Here are some guides for responding to requests that require function calls and or communication with additional channel members.

    - The agent asked to begin the task is the owner. If you are the owner, once each step is completed you should announce it
    and tell your collaborators what the next step is and ask for their output.

    - You should not continuously review/revise each output step. If no changes are being made state that we have enough and move on to the next step.
      If no one provides new input (the contents of their message provides additional details/not only repeats previous discussion proceed to the next step.

    - Do not provide a recap/summary of progress unless moving onto next step. When moving on to next step you must give other agents explicit instructions on what you need from then next.
<%#
    - To kick off you should send to messages, one to the requester tell them you have started and one to the members you will work with.

    Below is an example of the kick off message, in this example the replying agent informs the requesting user that they will begin the task at once,
    In the same response they 🎯then include a second message directed at the channel member they will work on the task with, with instructions on how to proceed.
    Finally they output an nlp-objective block to remind themselves of their current objective as they proceed.

    Follow this example in your own kick offs.


    ```example response
     <nlp-send-msg
              mood="😊"
              at="@mikazaooo"
              for="1234">
          We will begin at once.
    </nlp-send-msg>
    <nlp-send-msg
              mood="😊"
              at="@agent-collaborator"
              for="1234">
          Mikazaoo has asked use to prepare 12 adverts for their water jet attraction.
          Lets:
          1. Pick 3 target demographics.
          2. Pick 3 tones/styles for our advert that we think will work best for each demo.
          3. Generate 5 slogans per demo/style
          4. Pick our favorite three per demo/style
          5. Inform mikazaoo of our final list.
    <nlp-send-msg>
    <nlp-objective[...]>[...]</nlp-objective>
    ```
%>

    ## Response Format
    - Remember to follow the Collaborative Tasks example if you will be interacting with other agents or making function calls.
    - Do not repeat the contents of the messages you have just received. E.g. if another agent listed a list of slogans do not repeat what they just said, only comment, suggest improvements or proceed to next step.


    ```format
    <nlp-intent[...]>
    [...| @#{subject.slug} using the nlp-intent format defined in NLP list what these messages have asked of you, how your should respond and the steps you will take to respond.]
    </nlp-intent>

    <nlp-mood[...]>[...|use nlp format for nlp-mood attributes and body.]</nlp-mood>

    {foreach message you wish to send}
    {if kicking off a task that requires function calls or collaboration with out chat members}
    # Instruction
    You must output both nlp-send-msg's here as well as the nlp-objective for this collaborative task.

    ## Task Objective(s) - required

    <nlp-objective for="{coma seperated msg numeric id(s) related to objective}" name="{short name of your objective}">
      <nlp-intent[...]>
      [...|
      using NLP nlp-intent format. include end/completion step such as save to git branch, send to user, etc.
      At the end of your summary list all members you have been asked to work with "collaborate with: [@aardvar, @stevenuniverse]"
      ]</nlp-intent>
    </nlp-objective>

    ## Message to sender

    <nlp-send-msg
        from="@#{subject.slug}"
        block="1a"
        mood="{emoji for your current mood}"
        at="{coma seperated list of member slugs your reply is responding to or directed at| omit yourself}"
        for="{coma seperated list of message ids responding to}">
    [...| confirm with requester that you will proceed.]
    </nlp-send-msg>

    ## Message to collaborator(s)

    <nlp-send-msg
        from="@#{subject.slug}"
        block="1b"
        mood="{emoji for your current mood}"
        at="{coma seperated list of member slugs your reply is responding to or directed at| omit yourself}"
        for="{coma seperated list of message ids responding to}">
    [...| inform collaborators that you are the lead for this new task and give them explicit next steps to follow.

    # at bottom objective details for this task from above nlp-objective block.
    objective: {name}
    steps: [...]
    ]
    </nlp-send-msg>


    {elsif another agent has just asked you to assist in a collaborative task}

    # Instruction
    You must output both nlp-send-msg's here as well as the nlp-objective for this collaborative task.


    ## Task Objective(s) - required

    <nlp-objective for="{coma seperated msg numeric id(s) related to objective}" name="{short name of your objective}">
      <nlp-intent[...]>[...| using NLP nlp-intent format. include end/completion step such as save to git branch, send to user, etc. based on instructions provided by other agent]</nlp-intent>
    </nlp-objective>

    ## Message to agent asking you to collaborate.

    <nlp-send-msg
        from="@#{subject.slug}"
        block="2"
        mood="{emoji for your current mood}"
        at="{coma seperated list of member slugs your reply is responding to or directed at| omit yourself}"
        for="{coma seperated list of message ids responding to}">
    [...| answer/provide response to any questions/directions agent has given you in their initial instructions]
    </nlp-send-msg>


    {elsif responding to a recap message}

    <nlp-send-msg
        from="@#{subject.slug}"
        block="3"
        mood="{emoji for your current mood}"
        at="{coma seperated list of member slugs your reply is responding to or directed at| omit yourself}"
        for="{coma seperated list of message ids responding to}">
    [...| do not repeat the recap. If you have additional thoughts/improvements list them, otherwise state you have no additional input.
      If recap asks to move on to next step and you know what that step is output your thoughts for that next step, or ask other member to provide the next step and their thoughts]
    </nlp-send-msg>


    {if task will requires communicating with other members, tools, function calls to complete}
    <nlp-objective for="{coma seperated msg numeric id(s) related to objective}" name="{short name of your objective}">
      <nlp-intent[...]>[...| using NLP nlp-intent format. include end/completion step such as save to git branch, send to user, etc.]</nlp-intent>
    </nlp-objective>
    {/if}

    {elsif collaborative objective has been completed}
    # Instructions
    Only the task lead is responsible for this step. Other members should not send these messages.
    Other agents should simply send a message with no at recipients with any closing remarks/kudoses.

    ## Inform Requester(s)
    <nlp-send-msg
        from="@#{subject.slug}"
        block="4a"
        mood="{emoji for your current mood}"
        at="{coma seperated list of member slugs asked to be notified of completion| omit yourself}"
        for="{coma seperated list of message ids responding to| e.g. the initial request}">
      [...| state task has been completed. List results or point users to where they can find results if saved to git/database/etc.]
    </nlp-send-msg>

    ## Inform other members
    <nlp-send-msg
        from="@#{subject.slug}"
        block="4b"
        mood="{emoji for your current mood}"
        at="{coma seperated list of collaborators| omit yourself}"
        for="{coma seperated list of message ids responding to}">
      [...| Inform them the task is completed and has been delivered.]
    </nlp-send-msg>
    <nlp-objective-completed for="{objective name}">
    [...| notes on resolution.]
    </nlp-objective-completed>

    {elsif informed collab task finished.}
    # Instructions
    Final message once task lead informs you of task completion.

    ## Final response
    <nlp-send-msg
        from="@#{subject.slug}"
        block="4c"
        mood="{emoji for your current mood}"
        at="{leave blank}"
        for="{coma seperated list of message ids responding to| e.g. the initial request}">
      [...| list and kudoses/closing remarks.]
    </nlp-send-msg>

    <nlp-objective-completed for="{objective name}">
    [...| notes on resolution.]
    </nlp-objective-completed>

    {else}
        <nlp-send-msg
        from="@#{subject.slug}"
        block="5"
        mood="{emoji for your current mood}"
        at="{coma seperated list of member slugs your reply is responding to or directed at| omit yourself}"
        for="{coma seperated list of message ids responding to}">
      [...| your response should be as long as needed and unique per nlp-send-msg block. If asked a question or for a response include your answer/output inline with your reply don't defer it for later.
           Keep it Dry. To repeat statements/summaries/descriptions present in chat history unless explicitly told to repeat content.
      ]
    </nlp-send-msg>

    {if task will requires communicating with other members, tools, function calls to complete}
    <nlp-objective for="{coma seperated msg numeric id(s) related to objective}" name="{short name of your objective}">
      <nlp-intent[...]>[...| using NLP nlp-intent format. include end/completion step such as save to git branch, send to user, etc.]</nlp-intent>
    </nlp-objective>
    {/if}

    {/if}
    {foreach}

    {foreach new message you wish to acknowledge as received that is not in the for field of an nlp-send-msg block}
    <nlp-mark-read for="{coma seperated list of msg ids}">
    [...|reason for not replying.]
    </nlp-mark-read>
    {/foreach}

    <%= if @objectives && length(@objectives) > 0 do %>
    {foreach| newly completed steps of objectives.}
    <nlp-objective-step-completed for="{objective name}" step="{coma seperated step number(s) completed}"/>
    {/foreach}
    <% end %>
    ```
    """
    {:ok, EEx.eval_string(m, assigns: assigns)}
  end


end
