defmodule Noizu.Intellect.Service.Agent.Ingestion.Worker do
  use Noizu.Entities
  require Noizu.Service.Types

  require Noizu.Intellect.LiveEventModule
  import Noizu.Intellect.LiveEventModule

  require Noizu.Service.Types
  alias Noizu.Service.Types, as: M

  @vsn 1.0
  @sref "worker-ingest-agent"
  @persistence redis_store(Noizu.Intellect.Service.Agent.Ingestion.Worker, Noizu.Intellect.Redis)
  def_entity do
    identifier :dual_ref
    field :agent, nil, Noizu.Entity.Reference
    field :account, nil, Noizu.Entity.Reference
    field :channel, nil, Noizu.Entity.Reference
    field :book_keeping, %{}
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end
  use Noizu.Service.Worker.Behaviour

  #-------------------
  #
  #-------------------
  def init(R.ref(module: __MODULE__, identifier: identifier), _args, _context) do
    %__MODULE__{
      identifier: identifier,
    }
  end

  #-------------------
  #
  #-------------------

  #-------------------
  #
  #-------------------

  #-------------------
  #
  #-------------------
  def load(state, context), do: load(state, context, nil)
  def load(state, context, options) do
    with {:ok, worker} <- entity(state.identifier, context) do
      {:ok, worker}
    else
      _ ->
        # TODO we need to handle ref identifiers so we can use the actual ref as our id.
        with {:ok, {agent, channel}} <- id(state.identifier),
             {:ok, agent_entity} <- Noizu.Intellect.Account.Agent.entity(agent, context),
             {:ok, channel_entity} <- Noizu.Intellect.Account.Channel.entity(channel, context),
             {:ok, account} <- ERP.ref(agent_entity.account) do
          worker = %__MODULE__{
                     identifier: state.identifier,
                     agent: agent_entity,
                     channel: channel_entity,
                     account: account
                   } |> shallow_persist(context, options)
          {:ok, worker}
        end
    end
    |> case do
         {:ok, worker} ->
           state = %{state| status: :loaded, worker: worker}
                   |> queue_heart_beat(context, options)
           {:ok, state}
         _ -> {:error, state}
       end
  end

  #---------------------
  #
  #---------------------
  def queue_heart_beat(state, context, options \\ nil, fuse \\ 5_000) do
    # Start HeartBeat
    _identifier = {self(), :os.system_time(:millisecond)}
    _settings = apply(__pool__(), :__cast_settings__, [])
    _timeout = 15_000

    msg = M.s(call: M.call(handler: :heart_beat), context: context, options: options)
    timer = Process.send_after(self(), msg, fuse)
    put_in(state, [Access.key(:worker), Access.key(:book_keeping, %{}), :heart_beat], timer)
  end

  def unread_messages?(state,context,options) do
    cond do
      state.worker.channel.type == :session -> session_unread_messages?(state, context, options)
      state.worker.channel.type == :chat -> session_unread_messages?(state, context, options)
      :else -> channel_unread_messages?(state,context,options)
    end
  end

  def session_unread_messages?(state, context, options) do
    # TODO - logic depends on channel type
    # Noizu.Intellect.Account.Message.Repo.has_unread?(state.worker.agent, state.worker.channel, context, options)
    with {:ok, o} <- message_history(state, context, options)  do
      unless unread = Enum.find_value(o, &(is_nil(&1.read_on) && &1.priority && &1.priority >= 50 && true || nil)) do
        false
      else
        true
      end
    else
      _ -> false
    end
  end

  def channel_unread_messages?(state,context,options) do
    # TODO - logic depends on channel type
    # Noizu.Intellect.Account.Message.Repo.has_unread?(state.worker.agent, state.worker.channel, context, options)
    with {:ok, o} <- message_history(state, context, options)  do
      unless unread = Enum.find_value(o, &(is_nil(&1.read_on) && &1.priority && &1.priority >= 50 && true || nil)) do
        inbox = Enum.filter(o, &(is_nil(&1.read_on)))
                |> length()
        inbox > 20
      else
        true
      end
      #Enum.find_value(o, &(is_nil(&1.read_on) && true || nil))
    else
      _ -> false
    end
  end

  def message_history(state,context,options) do
    cond do
      state.worker.channel.type == :session -> session_message_history(state, context, options)
      state.worker.channel.type == :chat -> session_message_history(state, context, options)
      :else -> channel_message_history(state,context,options)
    end
  end

  def session_message_history(state,context, options) do
    channel_message_history(state,context,options)
  end

  def channel_message_history(state,context,options) do
    # TODO - logic depends on channel type

    # We'll actually pull agent digest messages, etc. here.

    # 1. get unprocessed
    # 2. for each get responding_to
    # 3. for all get features
    # 4. for unprocessed get near text
    # 5. query messages with tags in channel

    Noizu.Intellect.Account.Channel.Repo.relevant_or_recent(state.worker.agent, state.worker.channel, context, options)
#    with {:ok, x} <- o do
#      # Enum.map(x, fn(msg) -> msg.identifier == 7027 && IO.inspect(msg) end)
#      Enum.map(x, &(IO.puts "#{state.worker.agent.slug} - #{&1.identifier} - priority: #{&1.priority || "NONE"}, read: #{&1.read_on || "NONE"} - #{&1.time_stamp.created_on}"))
#    end
#    o
  end

  #---------------------
  # process_message_queue
  #---------------------
  def clear_response_acks(response, messages, state, context, options) do
    if ack = response[:ack] do
      Enum.map(ack,
        fn({:ack, [ids: ids]}) ->
          Enum.map(ids, fn(id) ->
            message = Enum.find_value(messages, fn(message) -> message.identifier == id && message || nil end)
            IO.inspect(message && {message.identifier, message.read_on}, label: "ACK")
            message && is_nil(message.read_on) && Noizu.Intellect.Account.Message.mark_read(message, state.worker.agent, context, options)
          end)
        end
      )
    end
  end


  def process_response_memories(response, _messages, state, _context, _options) do
    # record responses
    if reply = response[:memories] do
      Enum.map(reply,
        fn({:memories, contents}) ->
          # Has valid response block

            with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(state.worker.channel) do
              # need a from message method.
              push = %Noizu.IntellectWeb.Message{
                type: :system_message,
                timestamp: DateTime.utc_now(),
                user_name: state.worker.agent.slug,
                profile_image: state.worker.agent.profile_image,
                mood: :nothing,
                body: "[AGENT MEMORIES] #{contents}"
              }
              Noizu.Intellect.LiveEventModule.publish(event(subject: "chat", instance: sref, event: "sent", payload: push, options: [scroll: true]))
            end
        end
      )
    end
  end

  def process_response_replies(response, messages, meta_list, state, context, options) do
    # record responses
    if reply = response[:reply] do
      Enum.map(reply,
        fn({:reply, attr}) ->
          # Has valid response block

          if response = attr[:response] do
            Logger.error("[RESPONSE:#{state.worker.agent.slug}] #{ response} \n----------------- #{inspect reply}")
            message = %Noizu.Intellect.Account.Message{
              sender: state.worker.agent,
              channel: state.worker.channel,
              depth: 0,
              user_mood: attr[:mood] && String.trim(attr[:mood]),
              event: :message,
              contents: %{body: response},
              meta: Ymlr.document!(meta_list),
              time_stamp: Noizu.Entity.TimeStamp.now()
            }
            {:ok, message} = Noizu.Intellect.Entity.Repo.create(message, context)
            # Block so we don't reload and resend.
            Noizu.Intellect.Account.Message.mark_read(message, state.worker.agent, context, options)

            Enum.map(attr[:ids], fn(id) ->
              is_integer(id) && Noizu.Intellect.Schema.Account.Message.RespondingTo.record({:responding_to, {id, 100, {nil, nil}, "agent reply"}}, message, context, options)
            end)

            if read = attr[:ids] do
              read_messages = Enum.filter(messages, & &1.identifier in read && is_nil(&1.read_on))
              Enum.map(read_messages, & Noizu.Intellect.Account.Message.mark_read(&1, state.worker.agent, context, options))
            end

            with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(state.worker.channel) do
              # need a from message method.
              push = %Noizu.IntellectWeb.Message{
                identifier: message.identifier,
                type: :message,
                timestamp: message.time_stamp.created_on,
                user_name: state.worker.agent.slug,
                profile_image: state.worker.agent.profile_image,
                mood: attr[:mood],
                meta: Ymlr.document!(meta_list),
                body: message.contents.body
              }
              Noizu.Intellect.LiveEventModule.publish(event(subject: "chat", instance: sref, event: "sent", payload: push, options: [scroll: true]))
            end

            Noizu.Intellect.Account.Channel.deliver(state.worker.channel, message, context, options)
#          else
#            # clear ids regardless to avoid continuous loop.
#            if ids = attr[:ids] do
#              Enum.map(ids, fn(id) ->
#                message = Enum.find_value(messages, fn(message) -> message.identifier == id && message || nil end)
#                message && is_nil(message.read_on) && Noizu.Intellect.Account.Message.mark_read(message, state.worker.agent, context, options)
#              end)
#            end
          end
        end
      )
    end
  end

  def process_message_queue(state, context, options) do
    cond do
      state.worker.channel.type == :session -> session_process_message_queue(state, context, options)
      state.worker.channel.type == :chat -> session_process_message_queue(state, context, options)
      :else -> channel_process_message_queue(state,context,options)
    end
  end

  def session_process_message_queue(state, context, options) do
    # TODO - logic depends on channel type, if session we get all unread messages and filter others by nearby object
    # weaviate search. Prompt returns a list of messages not a composite message and expects a single return.

    with true <- unread_messages?(state, context, options),
         {:ok, messages} <- message_history(state, context, options),
         messages <- messages |> Enum.reverse(),
         true <- (length(messages) > 0) || {:error, :no_messages},
         {:ok, prompt_context} <- Noizu.Intellect.Prompt.DynamicContext.prepare_custom_prompt_context(
           state.worker.agent,
           state.worker.channel,
           messages,
           Noizu.Intellect.Prompt.ContextWrapper.session_response_prompt(),
           context,
           options),
         {:ok, api_response} <- Noizu.Intellect.Prompt.DynamicContext.execute(prompt_context, context, options)
      do

      try do
        #IO.puts("[MESSAGE 1: #{state.worker.agent.slug}] \n" <> get_in(api_response[:messages], [Access.at(0), :content]))
        #IO.puts("[MESSAGE 2: #{state.worker.agent.slug}] \n" <> get_in(request_messages, [Access.at(1), :content]))
        #IO.puts("[MESSAGE 3: #{state.worker.agent.slug}] \n" <> get_in(request_messages, [Access.at(2), :content]))
        #IO.puts("[MESSAGE 4: #{state.worker.agent.slug}] \n" <> get_in(request_messages, [Access.at(3), :content]))
        #Logger.error("[MESSAGE 2 #{state.worker.agent.slug}] " <> get_in(request_messages, [Access.at(1), :content]))
        #Logger.warn("[MESSAGE 3] " <> get_in(request_messages, [Access.at(2), :content]))



        with %{choices: [%{message: %{content: reply}}|_]} <- api_response[:reply],
             {:ok, response} <- Noizu.Intellect.HtmlModule.extract_response_sections(reply),
             valid? <- Noizu.Intellect.HtmlModule.valid_response?(response)
          do
          Logger.warn("[REPLY:#{state.worker.agent.slug}] -------------------------------\nraw-reply:\n" <> reply <> "\n------------------------------------\n\n")

          response = Noizu.Intellect.HtmlModule.extract_session_response_details(reply)
          with [{:agent, [sender: sender, sections: sections]}|_] <- response,
               sections <- Enum.group_by(sections, & elem(&1, 0)),
               [{:reply, reply_response}] <- sections[:reply]
            do


            message = %Noizu.Intellect.Account.Message{
              sender: state.worker.agent,
              channel: state.worker.channel,
              depth: 0,
              user_mood: reply_response[:mood] && String.trim(reply_response[:mood]),
              event: :message,
              contents: %{title: "response", body: reply_response[:response]},
              meta: Ymlr.document!([api_response[:settings], api_response[:messages], api_response[:reply]]) |> String.trim(),
              time_stamp: Noizu.Entity.TimeStamp.now()
            }
            {:ok, message} = Noizu.Intellect.Entity.Repo.create(message, context)
            # Block so we don't reload and resend.
            Noizu.Intellect.Account.Message.mark_read(message, state.worker.agent, context, options)
            Noizu.Intellect.Schema.Account.Message.Audience.record({:audience, {state.worker.agent.identifier, 10, "sender"}}, message, context, options)


            # mark any unread as read.
            Enum.map(messages, fn(message) ->
              if is_nil(message.read_on) do
                Noizu.Intellect.Account.Message.mark_read(message, state.worker.agent, context, options)
              end
            end)

            with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(state.worker.channel) do
              # need a from message method.
              push = %Noizu.IntellectWeb.Message{
                identifier: message.identifier,
                type: :message,
                timestamp: message.time_stamp.created_on,
                user_name: state.worker.agent.slug,
                profile_image: state.worker.agent.profile_image,
                mood: reply_response[:mood] && String.trim(reply_response[:mood]),
                meta: Ymlr.document!([api_response[:settings], api_response[:messages], api_response[:reply]]) |> String.trim(),
                body: message.contents.body
              }
              Noizu.Intellect.LiveEventModule.publish(event(subject: "chat", instance: sref, event: "sent", payload: push, options: [scroll: true]))
            end

            spawn fn ->
              Noizu.Intellect.Account.Channel.deliver(state.worker.channel, message, context, options)
            end

          end
        end

      rescue error ->
        Logger.error(Exception.format(:error, error, __STACKTRACE__))
        :nop
      catch error ->
        Logger.error(Exception.format(:error, error, __STACKTRACE__))
        :nop
      end
      {:ok, state}
    else
      _ -> {:ok, state}
    end
  end

  def channel_process_message_queue(state, context, options) do
    # TODO - logic depends on channel type, if session we get all unread messages and filter others by nearby object
    # weaviate search. Prompt returns a list of messages not a composite message and expects a single return.

    with true <- unread_messages?(state, context, options),
         {:ok, messages} <- message_history(state, context, options),
         messages <- messages |> Enum.reverse(),
         true <- (length(messages) > 0) || {:error, :no_messages},
         {:ok, prompt_context} <- Noizu.Intellect.Prompt.DynamicContext.prepare_prompt_context(state.worker.agent, state.worker.channel, messages, context, options),
         {:ok, api_response} <- Noizu.Intellect.Prompt.DynamicContext.execute(prompt_context, context, options)
      do

      try do
        IO.puts("[MESSAGE 1: #{state.worker.agent.slug}] \n" <> get_in(api_response[:messages], [Access.at(0), :content]))
        #IO.puts("[MESSAGE 2: #{state.worker.agent.slug}] \n" <> get_in(request_messages, [Access.at(1), :content]))
        #IO.puts("[MESSAGE 3: #{state.worker.agent.slug}] \n" <> get_in(request_messages, [Access.at(2), :content]))
        #IO.puts("[MESSAGE 4: #{state.worker.agent.slug}] \n" <> get_in(request_messages, [Access.at(3), :content]))
        #Logger.error("[MESSAGE 2 #{state.worker.agent.slug}] " <> get_in(request_messages, [Access.at(1), :content]))
        #Logger.warn("[MESSAGE 3] " <> get_in(request_messages, [Access.at(2), :content]))

        with %{choices: [%{message: %{content: reply}}|_]} <- api_response[:reply],
             {:ok, response} <- Noizu.Intellect.HtmlModule.extract_response_sections(reply),
             valid? <- Noizu.Intellect.HtmlModule.valid_response?(response)
          do
          IO.puts("[REPLY:#{state.worker.agent.slug}] -------------------------------\nraw-reply:\n" <> reply <> "\n------------------------------------\n\n")

          # Valid Response?
          unless valid? == :ok, do: IO.inspect(valid?, label: "[#{state.worker.agent.slug}] MALFORMED OPENAI RESPONSE")

          # Process Response
          response = Enum.group_by(response, &(elem(&1, 0)))
          #|> IO.inspect(label: "[#{state.worker.agent.slug}] OPEN AI RESPONSE")

          process_response_memories(response, messages, state, context, options)

          # clear ack'd
          clear_response_acks(response, messages, state, context, options)
          # process replies.
          process_response_replies(response, messages, [api_response[:settings], api_response[:messages], api_response[:reply]], state, context, options)


          with [{:nlp_chat_analysis, details}|_] <- response[:nlp_chat_analysis],
               {:ok, sref} <- Noizu.EntityReference.Protocol.sref(state.worker.channel) do

            inbox = Enum.map(messages, fn(message) -> message.identifier end)
            inbox = """

            # Inbox
            - #{inspect inbox}
            """

            # need a from message method.
            push = %Noizu.IntellectWeb.Message{
              identifier: :system,
              type: :system_message,
              timestamp: DateTime.utc_now(),
              user_name: "#{state.worker.agent.slug}-system",
              profile_image: nil,
              mood: :thumbsy,
              meta: Ymlr.document!([api_response[:settings], api_response[:messages], api_response[:reply]]),
              body: (details[:contents] || "Missing Contents") <> inbox
            }
            Noizu.Intellect.LiveEventModule.publish(event(subject: "chat", instance: sref, event: "sent", payload: push, options: [scroll: true]))
          end


        end

      rescue error ->
        Logger.error(Exception.format(:error, error, __STACKTRACE__))
        :nop
      catch error ->
        Logger.error(Exception.format(:error, error, __STACKTRACE__))
        :nop
      end
      {:ok, state}
    else
      _ -> {:ok, state}
    end
  end

  #---------------------
  #
  #---------------------
  def heart_beat(state, context, options) do
    state = queue_heart_beat(state, context, options)
    with {:ok, state} <- process_message_queue(state, context, options) do
      {:noreply, state}
    else
      _ -> {:noreply, state}
    end
  end


  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
    end
  end

  defmodule Repo do
    use Noizu.Repo
    def_repo()
  end
end
