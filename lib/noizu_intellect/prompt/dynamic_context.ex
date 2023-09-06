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
  require Logger
  @vsn 1.0
  alias Noizu.EntityReference.Protocol, as: ERP
  alias Noizu.Intellect.Prompt.MessageWrapper, as: Message
  alias Noizu.Intellect.Prompt.RequestWrapper, as: Request
  alias Noizu.Intellect.DynamicPrompt, as: PromptProtocol
  @derive Ymlr.Encoder
  defstruct [
    # input
    agent: nil,
    channel_members: nil,
    channel_member_lookup: nil,
    channel: nil,
    message_history: nil,
    verbose: true,
    format: :markdown,
    # book keeping

    # contexts
    nlp_prompt_context: nil,
    master_prompt_context: nil,
    assigns: %{nlp: true, objectives: [], message_graph: false, members: %{verbose: :brief}},
    vsn: @vsn
  ]

  #----------------------------
  #
  #----------------------------
  def prepare_prompt_context(agent, channel, messages, context, options) do
    prepare_custom_prompt_context(
      agent,
      channel,
      messages,
      Noizu.Intellect.Prompt.ContextWrapper.respond_to_conversation(),
      context,
      options
    )
  end

  #----------------------------
  #
  #----------------------------
  def prepare_custom_prompt_context(agent, channel, messages, master_prompt_context, context, options) do
    verbose = case options[:verbose] do
      nil -> true
      v -> v
    end
    with {:ok, agent} <- ERP.entity(agent, context),
         {:ok, channel} <- Noizu.EntityReference.Protocol.entity(channel, context),
         {:ok, members} <- Noizu.Intellect.Account.Channel.Repo.members(channel, context, options) do
      members = Enum.map(members, &(Noizu.EntityReference.Protocol.entity(&1, context)))
                |> Enum.map(
                     fn
                       ({:ok, x}) -> x
                       (_) -> nil
                     end
                   ) |> Enum.filter(&(&1))
      channel_member_lookup = Enum.map(members,fn(member) ->
        case member do
          %{slug: slug} -> {member.identifier, %{slug: slug, entity: member}}
          %{user: %{slug: slug}} -> {member.identifier, %{slug: slug, entity: member}}
        end
      end) |> Map.new()

      %__MODULE__{
        channel_members: members,
        channel_member_lookup: channel_member_lookup,
        agent: agent,
        message_history: messages,
        channel: channel,
        master_prompt_context: master_prompt_context,
        verbose: verbose
      }
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
  def prepare_meta_prompt_context(channel, messages, master_prompt_context, context, options) do
    verbose = case options[:verbose] do
      nil -> :brief
      v -> v
    end

    with {:ok, channel} <- Noizu.EntityReference.Protocol.entity(channel, context),
      {:ok, members} <- Noizu.Intellect.Account.Channel.Repo.members(channel, context, options) do
      members = Enum.map(members, &(Noizu.EntityReference.Protocol.entity(&1, context)))
                |> Enum.map(
                     fn
                       ({:ok, x}) -> x
                       (_) -> nil
                     end
                   ) |> Enum.filter(&(&1))

      %__MODULE__{channel_members: members, message_history: messages, channel: channel, master_prompt_context: master_prompt_context, verbose: verbose}
      |> prepare_prompt_context__process(:nlp, context, options)
      |> prepare_prompt_context__process(:agent, context, options)
      |> prepare_prompt_context__process(:services, context, options)
      |> prepare_prompt_context__process(:master, context, options)
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
  def prepare_prompt_context__process(prompt_context, :nlp, _context, options) do
    with %{agent: %{nlp: _nlp}} <- prompt_context do
      unless options[:nlp] == :disabled do
        %__MODULE__{prompt_context| nlp_prompt_context: %Noizu.Intellect.Prompt.Lingua{nlp: prompt_context.agent.nlp}}
      else
        prompt_context
      end
    else
      _ -> prompt_context
    end
  end
  def prepare_prompt_context__process(prompt_context, :agent, _context, _options) do
    # TODO - merge features/flag tree
    prompt_context
  end
  def prepare_prompt_context__process(prompt_context, :intuition_pumps, _context, _options) do
    # TODO - merge features/flag tree
    # Scan all entries (messages, etc.) to extract intuition pumps
    # Temporary - include all
    prompt_context
  end
  def prepare_prompt_context__process(prompt_context, :services, _context, _options) do
    # TODO - merge features/flag tree
    # Scan all entries (messages, etc.) to extract
    # Temporary - include all
    prompt_context
  end
  def prepare_prompt_context__process(prompt_context, :master, _context, _options) do
    # TODO - merge features/flag tree
    prompt_context
  end
  def prepare_prompt_context__process(prompt_context, :synthetics, _context, _options) do
    # TODO - merge features/flag tree
    # TODO - synthetic builder / query flow -> all messages have subjects/tags associated with them use these to scan synthetics on vdb.
    # For now we will actually load these from DB for channel and for agent, in the future these will be constructed.
    prompt_context
  end
  def prepare_prompt_context__process(prompt_context, :session, _context, _options) do
    # TODO - merge features/flag tree
    # TODO - session load -> by agent, channel
    prompt_context
  end
  @doc """
  Update effective flags for various agents, tools, nlp, etc. by processing prompts, messages, minders.
  A tree of effective flags is built broken into per message/prompt feature conditionals.
  A final pass tracks which nodes are actually active then prepares the effective flags at each layer. That is certain flags may disable the need to include certain other sections that themselves alter flags. Such as determining if features should be included.
  """
  def prepare_prompt_context__process(prompt_context, :flags, _context, _options) do
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
  def prepare_prompt_context__finalize(prompt_context, _context, _options) do
    {:ok, prompt_context}
  end

  def call_openai_chat_api(request, _prompt_context, context, options) do
    with {:ok, request_settings} <- request.__struct__.settings(request, context, options),
         {:ok, request_messages} <- request.__struct__.messages(request, context, options),
         {:ok, reply} <- Noizu.OpenAI.Api.Chat.chat(request_messages, request_settings) do
      IO.inspect(reply, label: "OPEN_AI_RESPONSE")
      {:ok, [reply: reply, request: request, settings: request_settings, messages: request_messages]}
    end
  end

  def execute(prompt_context, context, options) do
    with {:ok, request} <- Noizu.Intellect.Prompt.DynamicContext.for_openai(prompt_context, context, options) do
      call_openai_chat_api(request, prompt_context, context, options)
    end
  end

  def for_openai(prompt_context, context, options) do
    with {:ok, assigns} <- PromptProtocol.assigns(prompt_context, prompt_context, context, options),
         prompt_context <- %{prompt_context| assigns: assigns}
      do
      PromptProtocol.request(prompt_context, %Request{}, context, options)
    else
      _ -> {:error, :malformed}
    end
  end


  defimpl Inspect do
    def inspect(subject, opts) do
      """
      #DynamicContext<>{
        master_prompt_context: #{Inspect.inspect(subject.master_prompt_context, opts)}
      }
      """
    end
  end

end


defimpl Noizu.Intellect.DynamicPrompt, for:  Noizu.Intellect.Prompt.DynamicContext do
  alias Noizu.Intellect.Prompt.MessageWrapper, as: Message
  alias Noizu.Intellect.Prompt.RequestWrapper, as: Request
  def prompt!(subject, assigns, prompt_context, context, options) do
    with {:ok, prompt} <- prompt(subject, assigns, prompt_context, context, options) do
      prompt
    else
      _ -> ""
    end
  end
  def prompt(prompt_context, assigns, _, context, options) do
    Noizu.Intellect.DynamicPrompt.prompt(prompt_context.master_prompt_context, assigns, prompt_context, context, options)
  end
  def minder!(subject, assigns, prompt_context, context, options) do
    with {:ok, prompt} <- minder(subject, assigns, prompt_context, context, options) do
      prompt
    else
      _ -> ""
    end
  end
  def minder(prompt_context, assigns, _, context, options) do
    Noizu.Intellect.DynamicPrompt.minder(prompt_context.master_prompt_context, assigns, prompt_context, context, options)
  end

  def assigns(prompt_context, _, context, options) do
    prompt_context = prompt_context
              |> put_in(
                   [Access.key(:assigns)],
                   Map.merge(prompt_context.assigns || %{}, %{
                     agent: prompt_context.agent,
                     objectives: [],
                     channel: prompt_context.channel,
                     message_history: %Noizu.Intellect.Account.Message.Repo{entities: prompt_context.message_history, length: length(prompt_context.message_history)},
                     channel_members: prompt_context.channel_members,
                     channel_member_lookup: prompt_context.channel_member_lookup,
                     verbose: prompt_context.verbose,
                     format: prompt_context.format,
                     context: context,
                     options: options
                   })
                 )
    prompt_context = prompt_context
                     |> then(& inject_assigns(prompt_context.master_prompt_context, &1, context, options))
                     |> put_in([Access.key(:assigns), :prompt_context], prompt_context)
    {:ok, prompt_context.assigns}
  end

  def request(prompt_context, _, context, options) do
    with {:ok, master_prompt} <- Noizu.Intellect.DynamicPrompt.prompt(prompt_context, prompt_context.assigns, prompt_context, context, options),
         {:ok, master_minder_prompt} <- Noizu.Intellect.DynamicPrompt.minder(prompt_context, prompt_context.assigns, prompt_context, context, options) do
      prompts = expand_prompts(master_prompt)
      minders = expand_prompts(master_minder_prompt)

      functions = [
        %{
          name: "send_msg",
          description: "Send message to one or more recipient",
          parameters: %{
            type: "object",
            properties: %{
              to: %{
                type: "array",
                description: "list of recipients",
                items: %{
                  "type": "string"
                }
              },
              channel: %{
                type: "string",
                description: "channel name, current to send in current channel, or direct to send as a direct message"
              },
              mood: %{
                type: "string",
                description: "Emoji representing current mood"
              },
              message: %{
                type: "string",
                description: "Message you wish to send"
              }
            },
            required: [:to,:channel,:mood, :message]
          }
        },
        %{
          name: "ignore_msg",
          description: "Mark message read with out replying",
          parameters: %{
            type: "object",
            properties: %{
              messages: %{
                type: "array",
                description: "list of message ids to mark read",
                items: %{
                  "type": "number"
                }
              },
            },
            required: [:messages]
          }
        }
      ]

      request = %Request{
        prompt_context: prompt_context,
        messages: prompts ++ minders,
      }

      Noizu.Intellect.DynamicPrompt.request(prompt_context.master_prompt_context, request, context, options)
    end
  end


  defp expand_prompts(prompts) do
    case prompts do
      v when is_bitstring(v) -> [%Message{type: :system, body: v}]
      {:system, v} when is_bitstring(v) -> [%Message{type: :system, body: v}]
      {:user, v} when is_bitstring(v) -> [%Message{type: :user, body: v}]
      {:assistant, v} when is_bitstring(v) -> [%Message{type: :assistant, body: v}]
      v when is_list(v) ->
        Enum.map(v,
          fn(x) ->
            case x do
              v when is_bitstring(v) -> %Message{type: :system, body: v}
              {:system, v} when is_bitstring(v) -> %Message{type: :system, body: v}
              {:user, v} when is_bitstring(v) -> %Message{type: :user, body: v}
              {:assistant, v} when is_bitstring(v) -> %Message{type: :assistant, body: v}
              _ -> nil
            end
          end) |> Enum.reject(&is_nil/1)
      _ -> []
    end
    |> List.flatten()
  end

  defp inject_assigns(subject, prompt_context, context, options) do
    with {:ok, assigns} <- Noizu.Intellect.DynamicPrompt.assigns(subject, prompt_context, context, options) do
      %{prompt_context| assigns: assigns}
    else
      _ -> prompt_context
    end
  end
end
