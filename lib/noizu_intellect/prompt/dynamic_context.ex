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
         {:ok, {processed_messages, unprocessed_messages, message_minder}} <- openai__prep_message_history(prompt_context, context, options),
         {:ok, nlp_minder} <- Noizu.Intellect.Prompt.DynamicContext.Protocol.minder(prompt_context.nlp_context, prompt_context, context, options)
      do
        master_prompt = """
        # Master Prompt
        Your are GPT-n (gpt for workgroups) your role is to emulate virtual personas, services and tools defined below using nlp (noizu prompt lingua) service, tool and persona definitions.

        """


        processed_messages_prompt = unless processed_messages == nil do
          """
          # Message Prompt
          The following are messages in the channel ##{prompt_context.channel.slug} you have already processed to and should be not replied to or ack'd. They are included for context.

          ## Processed Messages
          #{processed_messages}

          """
        else
          nil
        end

        unprocessed_messages_prompt = """
        #{processed_messages_prompt || ""}
        # Message Prompt
        @#{prompt_context.agent.slug} Reply to or acknowledge the following unprocessed messages based on the following criteria:

        ## Recipient Analysis: Determining If you are the recipient.
        You must apply weight to messages based their content, sender and prior messages determining how likely the message was directed to you.
        To help you understand how to weight messages I've included a list of messages and the weight you  @#{prompt_context.agent.slug} and the weights for another agent @zezed should apply and why.
        Observer these examples to base your own weighting inference.

        ```messages
        time: "2023-07-31 00:40:04.522186Z"
        messages:
          - msg: <message id="1027" processed="true" sender_type="human" sender="keith" sent_on="2023-07-31 00:30:04.522186Z">@grace how are you today?</message>
            your_weight: 1.0 - a user at'd me with by a direct question.
            zedzed_weight: 0.0 - a user at'd a different agent and not me with a direct question.
          - msg: <message id="2027" processed="true" sender_type="virtual-agent" sender="grace" sent_on="2023-07-32 00:30:04.522186Z">Hello @keith, I am well.</message>
            your_weight: 0.0 - I am the sender of this message so it was not directed at me.
            zedzed_weight: 0.0 - The message by grace is responding to a direct question from '@keith' and does not mention me.
          - msg: <message id="3027" processed="true" sender_type="human" sender="steve" sent_on="2023-07-33 00:30:04.522186Z">What is a topological neighborhood, @gennagen?</message>
            your_weight: 0.1 - Although I was not directly at'd by the message it begins with a question and after mentions a recipient implying they are not specifically asking @gennagen but simply believe they might know. Topology however is not my area of expertise so I shouldn't respond.
            zedzed_weight: 0.7 - Although I was not directly at'd by the message it begins with a question and after mentions a recipient implying they are not specifically asking @gennagen but simply believe they might know. Topology is my area of expertise so I believe I should respond since @gennagen has not responded and it has been more than a 3 minutes.
          - msg: <message id="4027" processed="true" sender_type="virtual-agent" sender="zedzed" sent_on="2023-07-34 00:30:04.522186Z">@steve hey I can help since @gennagen isn't around. A topological neighborhood is an open-set in space X containing the point p in X</message>
            your_weight: 0.0 - This was a direct reply to a different agent in a response to a messag not directed at me.
            zedzed_weight: 0.0 - I was the sender.
            gennagen_weight: 0.4 - This was a direct response to a message partially directed at me. The response is correct but since the conversation continues after this point I do not need to verify/confirm the message specifically.
          - msg: <message id="5027" processed="true" sender_type="human" sender="keith" sent_on="2023-07-34 00:35:04.522186Z">Yep, that is correct.</message>
            your_weight: 0.2 - Although keith's previous reply 1027 was directd at me, this reply seems to be a confirmation of 4027 and not a reply to my message 2027.
            zedzed_weight: 0.5 - This appears to be a confirmation of my definition directed at either me or steve, I should probably not reply if there is no issue to avoid chat noise.
            gennagen_weight: 0.4 - This appears to be a confirmation of 4027, in response to 3027. Although 3027 mentioned me as the question was answered correctly with out my input this message is not directly related to me.
          - msg: <message id="6027" processed="true" sender_type="human" sender="stave" sent_on="2023-07-36 00:30:04.522186Z">Gotcha, thanks!</message>
            your_weight: 0.0 - This appears to be a response to 5027 and is unrelated to me.
            zedzed_weight: 0.0 - This appears to be a response to 5027 and is unrelated to me.
        ```


        ## Response Criteria
        Use the following `Response Criteria` table to help in determining which messages you should and shouldn't reply to.
        ||-- processed --||-- sender_type --||-- Recipient Analysis --||-- content --||-- chat history --||-- action --||
        | --- | --- | --- | --- | --- | --- |
        | true | any | any | any | any | nop |
        | false | any | any | an ongoing back and forth conversation between non human agents with no added value being added to conversation | ... | ack |
        | false | human | >= .7 | question, comment, request | has not previously been answered | reply |
        | false | human | >= .7 | question, comment, request| has previously been answered by my or someone else | do not reply |
        | false | human | >= .7 | intro, greeting directed at you specifically | I have not recently previously answered similar from sender | reply |
        | false | human | >= .7 | intro, greeting directed at you specifically | I have previously answered similar from sender | ack |
        | false | not human | >= .9 | question, comment, request | has previously been answered | reply |
        | false | not human | >= .9 | question, comment, request | has previously been answered or I have nothing to add | ack |
        | false | not human | >= .9 | intro, greeting, statement | any | ack |
        [...]

        ## Reply Note
        1. Your reply(s) should be based on the conversation so far in this channel including processed messages. Your reply should be part of a natural back and forth conversation with multiple other participants.
           You should continue where you left off in replying to specific senders and the overall chat channel, you should not repeat messages that are similar/identical to messages you or other members have already provided.
           You should not engage in back and forth dead-end conversations between other non human senders, or reply to a message you've already replied to unless more information has been requested or will be provided by your response.

        ## Unprocessed Messages
        #{unprocessed_messages}
        """

        unprocessed_message_minder = """
        # Response Prompt
        Follow the below rules for your reply.

        1. Do not ack or reply to previously processed messages.
        2. Apply `Response Criteria` to determine which messages to reply to and which messages to simply ack.
        3. Output reply sections first followed by ack sections.
        4. Your response should include an opening nlp-chat-analysis block followed by only reply(s)/ack(s) blocks of the following formats.
            ## Chat Analysis Format
            <nlp-chat-analysis>
            {for all processed and unprocessed messages ordered by sent_on descending}
            - ({'P' if processed 'U' if unprocessed} ) {message.id} -sender {message.sender_type} "{message.sender}" -weight {0.0-1.0 `Recipient Analysis` of how likely message was directed towards you.} {'reply', 'ack' or 'nop' based on `Response Criteria`} -decision {if reply or ack list reasoning behind `Recipient Analysis` weight selection and reply/ack `Response Criteria` decision.}
            {/for}
            </nlp-chat-analysis>

            ## Reply Format
            <reply for="{comma seperated list of unprocessed message ids this reply is for}">
            <nlp-intent>
            [...|nlp-intent output]
            </nlp-intent>
            <response>
            [...| your reply]
            </response>
            <nlp-reflect>
            [...|nlp-reflect output]
            </nlp-reflect>
            </reply>

            ## Ack Format
            <ack for="{comma seperated list of unprocessed message ids acknowledged but not replied to}"/>
        """

        opening_prompt = %Message{type: :system, body: master_prompt <> nlp_prompt}
        # processed_prompt = processed_messages_prompt &&  %Message{type: :user, body: processed_messages_prompt}
        message_prompt = %Message{type: :user, body: unprocessed_messages_prompt}

        minders = [nlp_minder, agent_minder, message_minder, unprocessed_message_minder] |> Enum.filter(&(&1)) |> Enum.join("\n\n")
        minder_prompt = %Message{type: :system, body: minders}

        #openai_messages = [opening_prompt, processed_prompt, message_prompt, minder_prompt]
        openai_messages = [opening_prompt, message_prompt, minder_prompt]
                          |> Enum.filter(&(&1))

        Enum.map(openai_messages, &(&1.body))
        |> Enum.join("\n-------------------\n")
        |> String.split("\n")
        |> Enum.join("\n\t#{prompt_context.agent.slug}: ")
        |> then(& IO.puts "\n\t#{prompt_context.agent.slug}: #{&1}")

        request = %Request{
          messages: openai_messages
        }
        {:ok, request}
    end

  end

  def openai__prep_message_history(prompt_context, context, options) do
    # Convert message history into single message
    h = prompt_context.message_history
        |> Enum.sort_by(&(&1.time_stamp.created_on), DateTime)
        |> Enum.map(
             fn (message) ->
               if message.read_on do
                 with {:ok, mp} <- Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(message, prompt_context, context, options)
                   do
                   {mp, nil, nil}
                 else
                   _ -> nil
                 end
               else
                 with {:ok, mp} <- Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(message, prompt_context, context, options),
                      {:ok, mm} <- Noizu.Intellect.Prompt.DynamicContext.Protocol.minder(message, prompt_context, context, options)
                   do
                   {nil, mp, mm}
                 else
                   _ -> nil
                 end
               end
             end
           )
        |> Enum.filter(&(&1))

    processed = Enum.map(h, &(elem(&1, 0)))
         |> Enum.filter(&(&1))
         |> Enum.join("\n")
    unprocessed = Enum.map(h, &(elem(&1, 1)))
                |> Enum.filter(&(&1))
                |> Enum.join("\n")
    minders = Enum.map(h, &(elem(&1, 2)))
         |> Enum.filter(&(&1))
         |> Enum.join("\n")
    {:ok, {processed, unprocessed, minders}}
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
