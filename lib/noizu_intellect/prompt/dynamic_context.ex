defmodule Noizu.Intellect.Prompt.DynamicContext do
  @moduledoc """
  @TODO
    channel.messages  <-> agent.channel.messages (digest, ignore, | sparse digesting, to fully populate we must query both tables)
    - redo message schema, use flat schema with single layer of message nesting/replies (for now), hook up to vector db
    - add agent message digest to flatten chat history into summarized messages with vector db search entries to query messages per agent.
      a message digest links to multiple messages so to build the list we query all message ids and join against the digest relation.
      we then flatten to list only standalone messages with no digest and digest messages, take uniques and prepare final message list.
    - channel - agent - minders  (user, system) -> system messages are further compacted when they grow in context size,
                channel message digests are built off of global plus channel to further compact context. The same query logic for compacting messages is used.
    - global - agent - minders (user, system) -> system messages are further compacted when they grow in context size.

  Synthetic memories use vector db.
  Message, Minders use postgres vector db.

  message(id, channel, depth, message, sender, status, created_on, modified_on, deleted_on)
  message_meta(message, flags: jsonb, services: jsonb, meta: jsonb)
     - flags set by message (for keeping after digestion and to speed up computation)
     - services referenced or needed for message (local models will eventually determine if messages require a service, crude systems until then will do so)
     - future
  message_subject(id, message, vector, subject, descriptions)
  message_subject_tag(id, message_subject, vector, tag)
  # Vectors
  agent_message_subject(id, agent, message, message_subject)
  agent_message_subject_tag(id, agent_message_subject, tag)
  message_subject(id, subject, vector)
  message_subject_tag(id, tag, vector)

  # Nesting
  message_ancestry(message, depth, ancestor)
      a message of depth 3 (channel.message < reply_1 < reply_to_reply_1 < reply_to_reply_to_reply_1) would have 3 entries.
     (reply_to_reply_to_reply_1, 0, channel.message)
     (reply_to_reply_to_reply_1, 1, reply_1)
     (reply_to_reply_to_reply_1, 2, reply_to_reply_1)
     this allows for left joining of arbitrary depth to construct the message tree.
  message_nesting(message, tuple) - a complementary table containing a tuple listing the materialized path (reply_to_reply_to_reply_1, (reply_1, reply_to_reply_1, reply_to_reply_1))
  agent_message(id, channel, message, sender, status, created_on, modified_on, deleted_on)
  agent_message_digest(id, message) # list of messages a given agent message is digesting.
  """

  @vsn 1.0
  alias Noizu.EntityReference.Protocol, as: ERP
  alias Noizu.Intellect.Prompt.MessageWrapper, as: Message
  alias Noizu.Intellect.Prompt.RequestWrapper, as: Request
  defstruct [
    # input
    agent: nil,
    channel: nil,
    message_history: nil,
    format: :markdown,
    # book keeping

    # contexts
    nlp_context: nil,

    vsn: @vsn
  ]

  #----------------------------
  #
  #----------------------------
  def assigns(subject, context, options) do
    {:ok, %{}}
  end

  #----------------------------
  #
  #----------------------------
  def prepare_prompt_context(agent, channel, messages, context, options) do
    with {:ok, agent} <- ERP.entity(agent, context) do
      %__MODULE__{agent: agent, message_history: messages, channel: channel}
      |> prepare_prompt_context__process(:nlp, context, options)
      |> prepare_prompt_context__process(:agent, context, options)
      |> prepare_prompt_context__process(:intuition_pumps, context, options)
      |> prepare_prompt_context__process(:services, context, options)
      |> prepare_prompt_context__process(:master, context, options)
      |> prepare_prompt_context__process(:synthetics, context, options)
      |> prepare_prompt_context__process(:session, context, options)
      |> prepare_prompt_context__process(:flags, context, options)
      |> prepare_prompt_context__finalize(context, options)
    end
  end

  #----------------------------
  #
  #----------------------------


  @doc """
  Populate subsection of dynamic prompt context.
    sections:
      nlp: Noizu Prompt Lingo related sections
      agent: Agent related sections
      intuition_pumps: intuition pumps
      services: dynamic selected services based on messages, agent, minders.
      master: master prompts and minders
      synthetics: agent synthetic memory and context (information on project, users)
      session: session related prompts, minders
  """
  def prepare_prompt_context__process(prompt_context, section, context, options)
  def prepare_prompt_context__process(prompt_context, :nlp, context, options) do
    %__MODULE__{prompt_context| nlp_context: %Noizu.Intellect.Prompt.Lingua{nlp: prompt_context.agent.nlp}}
  end
  def prepare_prompt_context__process(prompt_context, :agent, context, options) do
    # TODO - merge features/flag tree
    prompt_context
  end
  def prepare_prompt_context__process(prompt_context, :intuition_pumps, context, options) do
    # TODO - merge features/flag tree
    # Scan all entries (messages, etc.) to extract intuition pumps
    # Temporary - include all
    prompt_context
  end
  def prepare_prompt_context__process(prompt_context, :services, context, options) do
    # TODO - merge features/flag tree
    # Scan all entries (messages, etc.) to extract
    # Temporary - include all
    prompt_context
  end
  def prepare_prompt_context__process(prompt_context, :master, context, options) do
    # TODO - merge features/flag tree
    prompt_context
  end
  def prepare_prompt_context__process(prompt_context, :synthetics, context, options) do
    # TODO - merge features/flag tree
    # TODO - synthetic builder / query flow -> all messages have subjects/tags associated with them use these to scan synthetics on vdb.
    # For now we will actually load these from DB for channel and for agent, in the future these will be constructed.
    prompt_context
  end
  def prepare_prompt_context__process(prompt_context, :session, context, options) do
    # TODO - merge features/flag tree
    # TODO - session load -> by agent, channel
    prompt_context
  end
  @doc """
  Update effective flags for various agents, tools, nlp, etc. by processing prompts, messages, minders.
  A tree of effective flags is built broken into per message/prompt feature conditionals.
  A final pass tracks which nodes are actually active then prepares the effective flags at each layer. That is certain flags may disable the need to include certain other sections that themselves alter flags. Such as determining if features should be included.
  """
  def prepare_prompt_context__process(prompt_context, :flags, context, options) do
    # TODO - merge features/flag tree
    prompt_context
  end

  #------------------------------
  #
  #------------------------------
  @doc """
  Finalize/prune/tweak prompt struct.
  Prompt objects include flags to control whether or not to include.
  The finalize steps updates these flags to insure minimum final context size.
  It additionally sets model, flags, and final message set, and collapses/prunes synthetics
  """
  def prepare_prompt_context__finalize(prompt_context, context, options) do
    {:ok, prompt_context}
  end


  #------------------------------
  #
  #------------------------------
  @doc """
  Generate actual chat messages and functions to be sent to agent, and determine actual model
  and model settings to apply based on context, context size, flags and options.


  # opening_prompt:
  #   - nlp_prompt
  #   - agent_prompt
  #   - intuition_pump_prompts (agent specific)
  #   - service_prompts (agent and request specific)
  #   - master_prompt
  #   - agent_context
  #   - synthetic_memories
  # messages_prompt:
  #   - messages (recent + dynamic insertion), user system messages, collapsed messages, function call response messages (dynamic collapse)
  # minders:
  #   - intuition pump minders (dynamic)
  #   - service_minders (dynamic)
  #   - master_minder
  #   - nlp_minder
  #   - user_minders (user dynamic)
  #   - agent_minder
  #   - function_minder? -> or more detailed descriptions with future dynamic logic.
  #   - system minders (dynamic)
  #   - system flags (dynamic - constructed by prompt and message scanning)

  """
  def for_openai(prompt_context, context, options) do
    with {:ok, nlp_prompt} <- Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(prompt_context.nlp_context, prompt_context, context, options),
         {:ok, agent_prompt} <- Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(prompt_context.agent, prompt_context, context, options),
         {:ok, agent_minder} <- Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(prompt_context.agent, prompt_context, context, options),
         {:ok, {message_prompt, message_minder}} <- openai__prep_message_history(prompt_context, context, options),
    {:ok, nlp_minder} <- Noizu.Intellect.Prompt.DynamicContext.Protocol.minder(prompt_context.nlp_context, prompt_context, context, options)
      do
        master_prompt = """
        # Master Prompt
        Your are GPT-n (gpt for workgroups) your role is to emulate virtual personas, services and tools
        defined below using nlp (noizu prompt lingua) service, tool and persona definitions.

        """

        process_message_prompt = """
        # Master Prompt
        Reply to any of the following unread messages.
        Do not reply to messages marked as read they are included to provide context.
        Do not reply to messages from other agents unless they are directed at you using @#{prompt_context.agent.slug}
        and warrant a response. Hello and greeting, how can I help, etc. messages from virtual-personas do not warrant replies.
        """

        process_message_minder = """
        # Prompt Response Format
        Reply to messages or group of messages using the below syntax to reply or not reply but acknowledge receipt of messages.
        Your response can include multiple replies/acks of the following formats.

        ## Reply Format
        <reply to="{coma seperated list of message ids this reply is for}">
        [...| your reply]
        </repl>

        ## Ack Format
        <ack for="{coma seperated list of message ids acknowledged but not replied to}"/>


        """

        opening_prompt = %Message{type: :system, body: master_prompt <> nlp_prompt <> process_message_prompt}

        message_prompt_open = """
        # Messages

        """
        message_prompt = %Message{type: :user, body: message_prompt_open <> message_prompt}



        minder_prompt = %Message{type: :system, body: process_message_minder <> nlp_minder <> "\n\n" <> (agent_minder && (agent_minder <> "\n\n") || "") <> message_minder}
        request = %Request{
          messages: [opening_prompt, message_prompt, minder_prompt]
        }
        {:ok, request}
    end

  end

  def openai__prep_message_history(prompt_context, context, options) do
    # Convert message history into single message
    h = Enum.map(prompt_context.message_history,
          fn(message) ->
            with {:ok, mp} <- Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(message, prompt_context, context, options),
                 {:ok, mm} <- Noizu.Intellect.Prompt.DynamicContext.Protocol.minder(message, prompt_context, context, options)
              do
              {mp, mm}
            else
              _ -> nil
            end
          end) |> Enum.filter(&(&1))

    mp = Enum.map(h, &(elem(&1, 0)))
         |> Enum.filter(&(&1))
         |> Enum.join("\n")

    mm = Enum.map(h, &(elem(&1, 1)))
         |> Enum.filter(&(&1))
         |> Enum.join("\n")
    {:ok, {mp, mm}}
  end


  #------------------------------
  #
  #------------------------------
  @doc """
  returns section related open ai chat completion message.
  section:
    open: opening system prompt
    messages: compacted messages
    close: closing minders and flags
  """
  def openai_chat_queue__section(section, prompt_context, context, options)
  def openai_chat_queue__section(:open, prompt_context, context, options) do
    nil
  end
  def openai_chat_queue__section(:messages, prompt_context, context, options) do
    nil
  end
  def openai_chat_queue__section(:close, prompt_context, context, options) do
    nil
  end
end
