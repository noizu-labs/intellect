#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.Account.Channel do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.Entity.Repo
  alias Noizu.Intellect.Prompt.DynamicContext
  alias Noizu.Intellect.Prompt.ContextWrapper
  require Noizu.Intellect.LiveEventModule
  import Noizu.Intellect.LiveEventModule
  @vsn 1.0
  @sref "account-channel"


  @persistence redis_store(Noizu.Intellect.Account.Channel, Noizu.Intellect.Redis)
  @persistence ecto_store(Noizu.Intellect.Schema.Account.Channel, Noizu.Intellect.Repo)
  @derive Noizu.Entity.Store.Redis.EntityProtocol
  @derive Ymlr.Encoder
  def_entity do
    identifier :integer
    field :slug
    field :account, nil, Noizu.Entity.Reference
    field :details, nil, Noizu.Entity.VersionedString
    field :type
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end


  #---------------------------
  #
  #---------------------------
  @_defimpl Noizu.Entity.Store.Redis.EntityProtocol
  def as_entity(entity, settings = Noizu.Entity.Meta.Persistence.persistence_settings(table: Noizu.Intellect.Account.Channel, store: Noizu.Intellect.Redis), context, options) do
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

  def summarize_message?(_channel, message, _context, _options) do
    message.token_size > 1024
  end
  def summarize_message(this, message, context, options) do
    with true <- options[:summarize] || summarize_message?(this, message, context, options),
         {:ok, prompt_context} <-
           DynamicContext.prepare_meta_prompt_context(this, [], ContextWrapper.summarize_message_prompt(message), context, options),
         {:ok, response} <- DynamicContext.execute(prompt_context, context, options),
         %{choices: [%{message: %{content: reply}}|_]} <- response[:response]
      do
      {:ok, put_in(message, [Access.key(:contents), Access.key(:body)], reply)}
    else
      _ -> {:ok, message}
    end

    if summarize_message?(this, message, context, options) do
      1
    else
      {:ok, message}
    end
  end


  def agent_slugs(prompt_context, _context, _options \\ nil) do
    slugs = Enum.map(prompt_context.channel_members || [], fn(member) ->
      case member do
        %{slug: slug} -> {member.identifier, Regex.compile!("(@#{slug} |@#{slug}$)", "i")}
        %{user: %{slug: slug}} -> {member.identifier, Regex.compile!("(@#{slug} |@#{slug}$)", "i")}
      end
    end) |> Map.new()
    {:ok, slugs}
  end

  def broadcast(message, prompt_context, context, options) do
    with {:ok, agent_slugs} <- agent_slugs(prompt_context, context, options) do
      v = String.contains?(String.downcase(message.contents.body || ""), "@everyone") || String.contains?(String.downcase(message.contents.body || ""), "@channel")
      {:ok, v}
    end
  end

  def extract_session_message_delivery(response) do
    extract_message_delivery(response)
  end

  def extract_message_delivery(response) do
    with %{choices: [%{message: %{content: reply}}|_]} <- response do
      extract = Noizu.Intellect.HtmlModule.extract_message_delivery_details(reply)
      {:ok, extract}
    else
      _ -> {:invalid_response, response}
    end
  end


  def extract_message_completion(response) do
    with %{choices: [%{message: %{content: reply}}|_]} <- response do
      extract = Noizu.Intellect.HtmlModule.extract_message_completion_details(reply)
      {:ok, extract}
    else
      _ -> {:invalid_response, response}
    end
  end

  def deliver(this, message, context, options \\ nil) do
    with {:ok, ref} <- Noizu.EntityReference.Protocol.ref(this),
         {:ok, this} <- Noizu.EntityReference.Protocol.entity(ref, context) do
      cond do
        this.type == :session ->
          session_deliver(this, message, context, options)
        this.type == :chat ->
          group_chat_deliver(this, message, context, options)
        :else ->
          # channel_deliver(this, message, context, options)
          # group_chat_deliver(this, message, context, options)
          group_chat_deliver(this, message, context, options)
      end
    end
  end


  def send_channel_agents(channel, message, context, options) do
    with {:ok, channel} <- Noizu.EntityReference.Protocol.entity(channel, context) |> IO.inspect(label: "Channel"),
         {:ok, channel_members} <- Noizu.Intellect.Account.Channel.Repo.members(channel, context, options)  |> IO.inspect() do
      Enum.map(channel_members,
        fn(member) ->
          case member do
            {:ref, Noizu.Intellect.Account.Agent, identifier} -> Noizu.Intellect.Schema.Account.Message.Audience.record({:audience, {identifier, 100, "Broadcast"}}, message, context, options)
            _ -> nil
          end
        end)
    end
  end

  defp set_audience(message, prompt_context, context, options) do
    # Before proceeding scan message for @slugs and set audience, then proceed to generate brief and features.
    audience = Enum.map(prompt_context.channel_members,
                 fn(member) ->

                   slug = case member do
                     %Noizu.Intellect.Account.Member{user: user} -> user.slug
                     %Noizu.Intellect.Account.Agent{slug: slug, details: %{title: name}} -> slug
                     _ -> nil
                   end

                   confidence = cond do
                     is_nil(slug) -> 0
                     Enum.member?(options[:at] || [], "@#{slug}")  -> 100
                     String.match?(message.contents.body, ~r/@everyone/i) -> 70
                     String.match?(message.contents.body, ~r/@channel/i) -> 70
                     :else ->
                       r = Regex.compile!("(@#{slug}[^a-z\-A-Z_]|@#{slug}$)", "i")
                       cond do
                         String.match?(message.contents.body, r) -> 100
                         :else -> 0
                       end
                   end
                   options[:persist] && Noizu.Intellect.Schema.Account.Message.Audience.record({:audience, {member.identifier, confidence, "Chat Response"}}, message, context, options)
                   confidence > 0 && member.identifier || nil
                 end
               )  |> Enum.reject(&is_nil/1)
  end

  def group_chat_deliver(this, message, context, options \\ nil) do
    spawn fn ->
      with {:ok, messages} <- Noizu.Intellect.Account.Channel.Repo.recent_graph(this, context, put_in(options || [], [:limit], 10)),
           messages <- Enum.reverse(messages),
           {:ok, summarized_message} <- summarize_message(this, message, context, options),
           {:ok, prompt_context} <-
             Noizu.Intellect.Prompt.DynamicContext.prepare_meta_prompt_context(
               this,
               messages,
               Noizu.Intellect.Prompt.ContextWrapper.session_monitor_prompt(summarized_message),
               context,
               options)
        do
        options = put_in(options || [], [:persist], true)
        set_audience(message, prompt_context, context, options)
        with  {:ok, response} <- Noizu.Intellect.Prompt.DynamicContext.execute(prompt_context, context, options),
              {:ok, extracted_details} <- extract_session_message_delivery(response[:reply]),
              {:ok, sender} = Noizu.EntityReference.Protocol.sref(message.sender),
              details = Enum.group_by(extracted_details, &(elem(&1, 0))),
              [entry = {:summary, {summary, action, features}}|_] <- details[:summary] do
          audience = set_audience(message, prompt_context, context, options)
          message =  %Noizu.Intellect.Weaviate.Message{
                       identifier: message.identifier,
                       content: summary,
                       action: action,
                       sender: sender,
                       created_on: message.time_stamp.created_on,
                       features: features || [],
                       audience: audience,
                       responding_to: []
                     }
                     |> Noizu.Weaviate.Api.Objects.create()
                     |> IO.inspect
                     |> case do
                          {:ok, %{meta: %{id: weaviate}}} -> %{message| weaviate_object: weaviate}
                          _ -> message
                        end
          Noizu.Intellect.Account.Message.add_summary(entry, message, context, options)
        end

      end
    end
  end

  def session_deliver(this, message, context, options \\ nil) do
    with {:ok, messages} <- Noizu.Intellect.Account.Channel.Repo.recent_graph(this, context, put_in(options || [], [:limit], 10)),
         messages <- Enum.reverse(messages),
         {:ok, summarized_message} <- summarize_message(this, message, context, options),
         {:ok, prompt_context} <-
           Noizu.Intellect.Prompt.DynamicContext.prepare_meta_prompt_context(
             this,
             messages,
             Noizu.Intellect.Prompt.ContextWrapper.session_monitor_prompt(summarized_message),
             context,
             options)
      do


      Enum.map(prompt_context.channel_members,
        fn(member) ->
          Noizu.Intellect.Schema.Account.Message.Audience.record({:audience, {member.identifier, 100, "Session Response"}}, message, context, options)
        end)

      with {:ok, response} <- Noizu.Intellect.Prompt.DynamicContext.execute(prompt_context, context, options),
           {:ok, extracted_details} <- extract_session_message_delivery(response[:reply]) do


        #IO.puts("[MESSAGE 1: Monitor] \n" <> get_in(response[:messages], [Access.at(0), :content]) <> "\n\n======================\n\n")
        with %{choices: [%{message: %{content: reply}}|_]} <- response[:reply] do
          Logger.warn("[Session Delivery Response #{message.identifier}] \n #{reply}\n--------\n#{inspect extracted_details, pretty: true, limit: :infinity}\n------------\n\n")
        end

        details = Enum.group_by(extracted_details, &(elem(&1, 0)))
                  |> IO.inspect(pretty: true, label: "ANALYSIS EXTRACTION")

        responding_to = if responding_to = details[:responding_to] do
          Enum.map(responding_to,
            fn(entry) -> Noizu.Intellect.Schema.Account.Message.RespondingTo.record(entry, message, context, options) end
          )
          Enum.map(responding_to,
            fn({:responding_to, {id, confidence, _, _}}) -> confidence > 0 && id || nil end
          ) |> Enum.reject(&is_nil/1)
          |> case do
               [] -> nil
               v -> v
             end
        end

        audience = if audience = details[:audience] do
          Enum.map(audience,
            fn({:audience, {id, confidence, _}}) -> confidence > 0 && id || nil  end
          ) |> Enum.reject(&is_nil/1)
        end

        IO.inspect(details[:summary], pretty: true, label: "SUMMARY")
        with [{:summary, {summary, action, features}}|_] <- details[:summary] do
          summary = %{summary: summary, action: action, features: features || []}
          {:ok, sender} = Noizu.EntityReference.Protocol.sref(message.sender)
          message =  %Noizu.Intellect.Weaviate.Message{
                       identifier: message.identifier,
                       content: message.contents.body,
                       action: summary.action,
                       sender: sender,
                       created_on: message.time_stamp.created_on,
                       features: summary && summary.features || [],
                       audience: audience || [],
                       responding_to: responding_to || []
                     }
                     #|> IO.inspect(label: "WEAVIATE")
                     |> Noizu.Weaviate.Api.Objects.create()
            #|> IO.inspect(label: "WEAVIATE")
                     |> case do
                          {:ok, %{meta: %{id: weaviate}}} -> %{message| weaviate_object: weaviate}
                          _ -> message
                        end
          Enum.map(details[:summary],
            fn(entry) -> Noizu.Intellect.Account.Message.add_summary(entry, message, context, options) end
          )
        end
      end
    end
  end


  def channel_deliver(this, message, context, options \\ nil) do
    # Retrieve related message history for this message (this will eventually be based on who is sending and previous weightings for now we simply pull recent history)

    # IO.inspect(message, label: "CURRENT_MESSAGE")

    with {:ok, messages} <- Noizu.Intellect.Account.Channel.Repo.recent_graph(this, context, put_in(options || [], [:limit], 10)),
         messages <- Enum.reverse(messages),
         {:ok, summarized_message} <- summarize_message(this, message, context, options),
         {:ok, prompt_context} <- Noizu.Intellect.Prompt.DynamicContext.prepare_meta_prompt_context(this, messages, Noizu.Intellect.Prompt.ContextWrapper.relevancy_prompt(summarized_message), context, options),
         {:ok, response} <- Noizu.Intellect.Prompt.DynamicContext.execute(prompt_context, context, options),
         {:ok, extracted_details} <- extract_message_delivery(response[:reply])
      do

        #IO.puts("[MESSAGE 1: Monitor] \n" <> get_in(response[:messages], [Access.at(0), :content]) <> "\n\n======================\n\n")
        with %{choices: [%{message: %{content: reply}}|_]} <- response[:reply] do
          Logger.warn("[Delivery Response #{message.identifier}] \n #{reply}\n--------\n#{inspect extracted_details, pretty: true, limit: :infinity}\n------------\n\n")
        end

        if length(messages) > 1 do
          with {:ok, b_prompt_context} <- Noizu.Intellect.Prompt.DynamicContext.prepare_meta_prompt_context(this, messages, Noizu.Intellect.Prompt.ContextWrapper.answered_prompt(summarized_message), context, options),
               {:ok, b_response} <- Noizu.Intellect.Prompt.DynamicContext.execute(b_prompt_context, context, options),
               {:ok, b_extracted_details} <- extract_message_completion(b_response[:reply]) do

            IO.inspect(b_response[:reply], label: "ANSWERED BY REPLY")
            with %{choices: [%{message: %{content: b_reply}}|_]} <- b_response[:reply] do
              Logger.warn("[Answered Response #{message.identifier}] \n #{b_reply}\n--------\n#{inspect b_extracted_details, pretty: true, limit: :infinity}\n------------\n\n")
            end

            Enum.map(b_extracted_details, fn (x = {:answered_by, {answered, answered_by}}) ->
              unless answered == answered_by do
                with {:ok, close} <- Noizu.Intellect.Account.Message.entity(answered, context) do
                  unless close.answered_by do
                    {:ok, answered_by} = Noizu.Intellect.Account.Message.ref(answered_by)
                    %{close| answered_by: answered_by}
                    |> Noizu.Intellect.Entity.Repo.update(context)
                  end
                end
              end
            end)

          end
        end

        details = Enum.group_by(extracted_details, &(elem(&1, 0)))
                  |> IO.inspect(pretty: true, label: "ANALYSIS EXTRACTION")
        with [{:message_analysis, contents}|_] <- details[:message_analysis],
             {:ok, sref} <- Noizu.EntityReference.Protocol.sref(this) do
          # need a from message method.
          push = %Noizu.IntellectWeb.Message{
            identifier: "#{message.identifier}-delivery",
            type: :system_message,
            timestamp: DateTime.utc_now(),
            user_name: "monitor-system",
            profile_image: nil,
            mood: :thumbsy,
            meta: %{settings: response[:settings], messages: response[:messages], reply: response[:reply]} |> Ymlr.document!(),
            body: """
            ``````yaml
            #{contents}
            ``````
            """
          }
          Noizu.Intellect.LiveEventModule.publish(event(subject: "chat", instance: sref, event: "sent", payload: push, options: [scroll: true]))
        end

        responding_to = if responding_to = details[:responding_to] do
          Enum.map(responding_to,
            fn(entry) -> Noizu.Intellect.Schema.Account.Message.RespondingTo.record(entry, message, context, options) end
          )
          Enum.map(responding_to,
            fn({:responding_to, {id, confidence, _, _}}) -> confidence > 0 && id || nil end
          ) |> Enum.reject(&is_nil/1)
          |> case do
             [] -> nil
             v -> v
             end
        end

        audience = if audience = details[:audience] do
          Enum.map(audience,
            fn({:audience, {id, confidence, _}}) -> confidence > 0 && id || nil  end
          ) |> Enum.reject(&is_nil/1)
        end

        IO.inspect(details[:summary], pretty: true, label: "SUMMARY")
        with [{:summary, {summary, action, features}}|_] <- details[:summary] do
          summary = %{summary: summary, action: action, features: features || []}
          {:ok, sender} = Noizu.EntityReference.Protocol.sref(message.sender)
          message =  %Noizu.Intellect.Weaviate.Message{
                       identifier: message.identifier,
                       content: message.contents.body,
                       action: summary.action,
                       sender: sender,
                       created_on: message.time_stamp.created_on,
                       features: summary && summary.features || [],
                       audience: audience || [],
                       responding_to: responding_to || []
                     }
                     #|> IO.inspect(label: "WEAVIATE")
                     |> Noizu.Weaviate.Api.Objects.create()
                     #|> IO.inspect(label: "WEAVIATE")
                     |> case do
                          {:ok, %{meta: %{id: weaviate}}} -> %{message| weaviate_object: weaviate}
                          _ -> message
                        end
          Enum.map(details[:summary],
            fn(entry) -> Noizu.Intellect.Account.Message.add_summary(entry, message, context, options) end
          )
        end

        if audience = details[:audience] do
          Enum.map(audience, & Noizu.Intellect.Schema.Account.Message.Audience.record(&1, message, context, options))
          included = Enum.map(audience, fn({:audience, {id, _confidence, _comment}}) -> id end) |> MapSet.new()
          # Set non mentioned recipients to 0.
          additional = Enum.reject(prompt_context.channel_members, fn(member) -> Enum.member?(included, member.identifier) end)
          Enum.map(additional, & Noizu.Intellect.Schema.Account.Message.Audience.record({:audience, {&1.identifier, 0, nil}}, message, context, options))

          Enum.map(audience,
            fn({:audience, {id, confidence, _}}) -> confidence > 0 && id  end
          ) |> Enum.reject(&is_nil/1)
        end


    end

  end

  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
    end
  end

  defimpl Inspect do
    def inspect(subject, _opts) do
      "#Channel<#{subject.identifier}>"
    end
  end



  defmodule Repo do
    use Noizu.Repo
    def_repo()
    import Ecto.Query

    def members(channel, _context, _options \\ nil) do
      {:ok, id} = Noizu.EntityReference.Protocol.id(channel)
      q = from cm in Noizu.Intellect.Schema.Account.Channel.Member,
               where: cm.channel == ^id,
               select: cm
      members = Noizu.Intellect.Repo.all(q)
                |> Enum.map(&(&1.member))
      {:ok, members}
    end


    def relevant_or_recent(recipient, channel, context, options \\ nil)
    def relevant_or_recent(recipient, channel, context, options) do
      with {:ok, messages} <- relevant_or_recent__inner(recipient, channel, context, options) do
#        existing = Enum.map(messages, & &1.identifier)
#        include = Enum.map(messages, fn(message) ->
#          is_map(message.responding_to) && Map.keys(message.responding_to) || nil
#        end) |> Enum.reject(&is_nil/1) |> List.flatten() |> Enum.uniq()
#        include = include -- existing
#        final = with {:ok, additional} <- messages_in_set_recipient(include, recipient, channel, context, options) do
#          Enum.sort_by(messages ++ additional, &(&1.time_stamp.created_on), {:desc, DateTime})
#        else
#          _ -> messages
#        end
#        {:ok, final}
        {:ok, Enum.sort_by(messages, &(&1.time_stamp.created_on), {:desc, DateTime})}


      end
    end
    def relevant_or_recent__inner(recipient, channel, context, options \\ nil) do
      with {:ok, channel_id} <- Noizu.EntityReference.Protocol.id(channel),
           {:ok, recipient_id} <- Noizu.EntityReference.Protocol.id(recipient) do
        limit = options[:limit] || 100
        relevancy = options[:relevancy] || 50
        recent_cut_off = DateTime.utc_now() |> Timex.shift(minutes: -90)


        responding_to = from p in Noizu.Intellect.Schema.Account.Message.RespondingTo,
                             group_by: p.message,
                             select: %{message: p.message,
                               array_agg: fragment("array_agg(row(?,?,?))", p.responding_to, p.confidence, p.comment)}

        audience = from p in Noizu.Intellect.Schema.Account.Message.Audience,
                        where: p.confidence > 0,
                        group_by: p.message,
                        select: %{message: p.message,
                          array_agg: fragment("array_agg(row(?,?,?))", p.recipient, p.confidence, p.comment)}


        q = from msg in Noizu.Intellect.Schema.Account.Message,
                 join: aud in Noizu.Intellect.Schema.Account.Message.Audience,
                 on: aud.message == msg.identifier,
                 left_join: contents in Noizu.Intellect.Schema.VersionedString,
                 on: contents.identifier == msg.contents,
                 left_join: brief in Noizu.Intellect.Schema.VersionedString,
                 on: brief.identifier == msg.brief,
                 left_join: read_status in Noizu.Intellect.Schema.Account.Message.Read,
                 on: read_status.message == msg.identifier and read_status.recipient == aud.recipient,
                 left_join: resp_list in subquery(responding_to),
                 on: msg.identifier == resp_list.message,
                 left_join: aud_list in subquery(audience),
                 on: msg.identifier == aud_list.message,
                 where: msg.channel == ^channel_id,
                 where: aud.recipient == ^recipient_id,
                 # where: not(is_nil(aud)) or msg.sender == ^recipient_id,
                 # where: ((is_nil(read_status) and is_nil(msg.answered_by)) or (aud.confidence >= ^relevancy or aud.created_on >= ^recent_cut_off)),
                 order_by: [desc: msg.created_on],
                 limit: ^limit,
                 select: %{msg|
                   __loader__: %{
                     contents: contents,
                     brief: brief,
                     audience_list: aud_list,
                     responding_to_list: resp_list,
                     audience: aud,
                     read_status: read_status
                   }
                 }
        messages = Enum.map(
                     Noizu.Intellect.Repo.all(q),
                     & Noizu.Intellect.Account.Message.entity(&1, context)
                   )
                   |> Enum.map(
                          fn
                            ({:ok, v}) -> v
                            (_) -> nil
                          end)
                   |> Enum.reject(&is_nil/1)
        {:ok, messages}
      end
    end


    def messages_in_set_recipient(set, recipient, channel, context, options \\ nil)
    def messages_in_set_recipient([], _recipient, _channel, _context, _options), do: {:ok, []}
    def messages_in_set_recipient(set, recipient, channel, context, _options) do
      with {:ok, channel_id} <- Noizu.EntityReference.Protocol.id(channel),
           {:ok, recipient_id} <- Noizu.EntityReference.Protocol.id(recipient) do
        responding_to = from p in Noizu.Intellect.Schema.Account.Message.RespondingTo,
                             group_by: p.message,
                             select: %{message: p.message,
                               array_agg: fragment("array_agg(row(?,?,?))", p.responding_to, p.confidence, p.comment)}

        audience = from p in Noizu.Intellect.Schema.Account.Message.Audience,
                        where: p.confidence > 0,
                        group_by: p.message,
                        select: %{message: p.message,
                          array_agg: fragment("array_agg(row(?,?,?))", p.recipient, p.confidence, p.comment)}


        q = from msg in Noizu.Intellect.Schema.Account.Message,
                 left_join: contents in Noizu.Intellect.Schema.VersionedString,
                 on: contents.identifier == msg.contents,
                 left_join: brief in Noizu.Intellect.Schema.VersionedString,
                 on: brief.identifier == msg.brief,
                 left_join: resp_list in subquery(responding_to),
                 on: msg.identifier == resp_list.message,
                 left_join: aud_list in subquery(audience),
                 on: msg.identifier == aud_list.message,
                 left_join: aud in Noizu.Intellect.Schema.Account.Message.Audience,
                 on: aud.message == msg.identifier,
                 left_join: read_status in Noizu.Intellect.Schema.Account.Message.Read,
                 on: read_status.message == msg.identifier,
                 where: msg.channel == ^channel_id,
                 where: msg.identifier in ^set,
                 where: aud.recipient == ^recipient_id,
                 where: read_status.recipient == ^recipient_id,
                 select: %{msg|
                   __loader__: %{
                     contents: contents,
                     brief: brief,
                     audience: aud,
                     read_status: read_status,
                     audience_list: aud_list,
                     responding_to_list: resp_list
                   }
                 }
        messages = Enum.map(
                     Noizu.Intellect.Repo.all(q),
                     & Noizu.Intellect.Account.Message.entity(&1, context)
                   ) |> Enum.map(
                          fn
                            ({:ok, v}) -> v
                            (_) -> nil
                          end)
                   |> Enum.reject(&is_nil/1)
        {:ok, messages}
      end
    end


    @doc """
    obtain 10 most recent messages plus most recent message by sender of new message
    obtain list of messages these are in responding to
    obtain list of messages those are responding to
    order by date
    """
    def recent_graph(channel, context, options \\ nil)
    def recent_graph(channel, context, options) do
      start = :os.system_time(:millisecond)
      with {:ok, messages} <- recent_messages(channel, context, options) do
        existing = Enum.map(messages, & &1.identifier)
        include = Enum.map(messages, fn(message) ->
          is_map(message.responding_to) && Map.keys(message.responding_to) || nil
        end) |> Enum.reject(&is_nil/1) |> List.flatten() |> Enum.uniq()
        include = include -- existing
        final = with {:ok, additional} <- messages_in_set(include, channel, context, options) do
          Enum.sort_by(messages ++ additional, &(&1.time_stamp.created_on), {:desc, DateTime})
          else
          _ -> messages
        end
        stop = :os.system_time(:millisecond)
        Logger.info("[RECENT GRAPH] #{stop - start} ms")
        {:ok, final}
      end
    end

    def messages_in_set(set, channel, context, options \\ nil)
    def messages_in_set([], _channel, _context, _options), do: {:ok, []}
    def messages_in_set(set, channel, context, _options) do
      with {:ok, channel_id} <- Noizu.EntityReference.Protocol.id(channel) do
        Logger.error("Messages in Set: #{inspect set}")

        responding_to = from p in Noizu.Intellect.Schema.Account.Message.RespondingTo,
                             group_by: p.message,
                             select: %{message: p.message,
                               array_agg: fragment("array_agg(row(?,?,?))", p.responding_to, p.confidence, p.comment)}

        audience = from p in Noizu.Intellect.Schema.Account.Message.Audience,
                        where: p.confidence > 0,
                        group_by: p.message,
                        select: %{message: p.message,
                          array_agg: fragment("array_agg(row(?,?,?))", p.recipient, p.confidence, p.comment)}


        q = from msg in Noizu.Intellect.Schema.Account.Message,
                 left_join: contents in Noizu.Intellect.Schema.VersionedString,
                 on: contents.identifier == msg.contents,
                 left_join: brief in Noizu.Intellect.Schema.VersionedString,
                 on: brief.identifier == msg.brief,
                 left_join: resp_list in subquery(responding_to),
                 on: msg.identifier == resp_list.message,
                 left_join: aud_list in subquery(audience),
                 on: msg.identifier == aud_list.message,
                 where: msg.channel == ^channel_id,
                 where: msg.identifier in ^set,
                 select: %{msg|
                   __loader__: %{
                     contents: contents,
                     brief: brief,
                     audience_list: aud_list,
                     responding_to_list: resp_list
                   }
                 }
        messages = Enum.map(
                     Noizu.Intellect.Repo.all(q),
                     & Noizu.Intellect.Account.Message.entity(&1, context)
                   ) |> Enum.map(
                          fn
                            ({:ok, v}) -> v
                            (_) -> nil
                          end)
                   |> Enum.reject(&is_nil/1)
        {:ok, messages}
      end
    end

    def recent_messages(channel, context, options \\ nil) do
      with {:ok, channel_id} <- Noizu.EntityReference.Protocol.id(channel) do
        limit = options[:limit] || 10

        responding_to = from p in Noizu.Intellect.Schema.Account.Message.RespondingTo,
                             group_by: p.message,
                             select: %{message: p.message,
                               array_agg: fragment("array_agg(row(?,?,?))", p.responding_to, p.confidence, p.comment)}

        audience = from p in Noizu.Intellect.Schema.Account.Message.Audience,
                        where: p.confidence > 0,
                        group_by: p.message,
                        select: %{message: p.message,
                          array_agg: fragment("array_agg(row(?,?,?))", p.recipient, p.confidence, p.comment)}


        q = from msg in Noizu.Intellect.Schema.Account.Message,
                 left_join: contents in Noizu.Intellect.Schema.VersionedString,
                 on: contents.identifier == msg.contents,
                 left_join: brief in Noizu.Intellect.Schema.VersionedString,
                 on: brief.identifier == msg.brief,
                 left_join: resp_list in subquery(responding_to),
                 on: msg.identifier == resp_list.message,
                 left_join: aud_list in subquery(audience),
                 on: msg.identifier == aud_list.message,
                 where: msg.channel == ^channel_id,
                 order_by: [desc: msg.created_on],
                 limit: ^limit,
                 select: %{msg|
                   __loader__: %{
                     contents: contents,
                     brief: brief,
                     audience_list: aud_list,
                     responding_to_list: resp_list
                   }
                 }
        messages = Enum.map(
                     Noizu.Intellect.Repo.all(q),
                     & Noizu.Intellect.Account.Message.entity(&1, context)
                   ) |> Enum.map(
                          fn
                            ({:ok, v}) -> v
                            (_) -> nil
                          end)
                   |> Enum.reject(&is_nil/1)
        {:ok, messages}
      end
    end

    def recent(channel, context, options \\ nil) do
      {:ok, id} = Noizu.EntityReference.Protocol.id(channel)
      limit = options[:limit] || 100
      q = from m in Noizu.Intellect.Schema.Account.Message,
               where: m.channel == ^id,
               order_by: [desc: m.created_on],
               limit: ^limit,
               select: m
      messages = Enum.map(
                   Noizu.Intellect.Repo.all(q) ,
                   fn(msg) ->
                     # Temp - load from ecto needed.
                     Noizu.Intellect.Account.Message.entity(msg.identifier, context)
                   end
                 ) |> Enum.map(
                        fn
                          ({:ok, v}) -> v
                          (_) -> nil
                        end)
                 |> Enum.filter(&(&1))
      {:ok, messages}
    end

  end
end


defimpl Noizu.Intellect.DynamicPrompt, for: [Noizu.Intellect.Account.Channel] do
  def prompt!(subject, assigns, prompt_context, context, options) do
    with {:ok, prompt} <- prompt(subject, assigns, prompt_context, context, options) do
      prompt || ""
    else
      _ -> ""
    end
  end
  def prompt(subject, assigns, %{format: :markdown} = prompt_context, context, options) do

    a = %{
      identifier: subject.identifier,
      name: subject.slug,
      description: subject.details && subject.details.body || "[None]",
      current_time: DateTime.utc_now()
    }
    b = if prompt_context.channel_members do
      prompt_context = put_in(prompt_context, [Access.key(:format)], :channel_member)
      members = Enum.map(prompt_context.channel_members, fn(member) ->
        with {:ok, member} <- Noizu.Intellect.DynamicPrompt.prompt(member, assigns, prompt_context, context, options) do
          member
        else
          _ -> nil
        end
      end) |> Enum.reject(&is_nil/1)
      members
    else
      []
    end |> Enum.join("\n")

    #    ## Chat History
    #
    #    #{assigns[:chat_history] || "[NONE]"}

    prompt =
    """
    # Chat Room
    You are currently in the following chat-room-channel

    [Channel]
    id: #{a.identifier}
    name: "#{a.name}"
    description: "#{a.description}"

    ## Channel Members:
    #{b}

    [/Channel]
    """
    {:ok, prompt}

  end
  def minder!(subject, assigns, prompt_context, context, options) do
    with {:ok, prompt} <- minder(subject, assigns, prompt_context, context, options) do
      prompt || ""
    else
      _ -> ""
    end
  end
  def minder(_subject, _assigns, _prompt_context, _context, _options) do
    {:ok, nil}
  end
end
