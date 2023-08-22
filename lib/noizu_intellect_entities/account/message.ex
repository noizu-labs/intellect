#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.Account.Message do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.Entity.Repo

  @vsn 1.0
  @sref "account-message"
  @persistence redis_store(Noizu.Intellect.Account.Message, Noizu.Intellect.Redis)
  @persistence ecto_store(Noizu.Intellect.Schema.Account.Message, Noizu.Intellect.Repo)
  @derive Noizu.Entity.Store.Redis.EntityProtocol
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  @derive Ymlr.Encoder
  def_entity do
    identifier :integer
    field :weaviate_object
    field :sender, nil, Noizu.Entity.Reference
    field :channel, nil, Noizu.Entity.Reference
    field :answered_by, nil, Noizu.Entity.Reference
    @store [name: :read_status]
    field :read_on, nil, Noizu.Entity.DerivedField, [pull: {:load, [:read_on]}]

    @store [name: :audience]
    field :priority, nil, Noizu.Entity.DerivedField, [pull: {:load, [{:confidence, :__defualt__, :check}]}]

    @store [name: :audience_list]
    field :audience, nil, Noizu.Entity.DerivedField, [pull: &__MODULE__.unpack_audience_list/4] # todo provide a method to unpack the tuple
    @store [name: :responding_to_list]
    field :responding_to, nil, Noizu.Entity.DerivedField, [pull: &__MODULE__.unpack_responding_to_list/4] # todo provide a method to unpack the tuple

    field :note

    field :depth
    field :user_mood #, nil, Noizu.Intellect.Emoji
    field :event #, nil, Noizu.Intellect.Message.Event
    field :token_size
    field :contents, nil, Noizu.Entity.VersionedString
    field :brief, nil, Noizu.Entity.VersionedString
    field :meta
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end
  import Ecto.Query
  require Noizu.Entity.Meta.Persistence


  def sender_details(message, context, options \\ nil)
  def sender_details(message, _, _) do
    case message.sender do
      %Noizu.Intellect.Account.Member{user: user} -> {user.slug, "human operator"}
      %Noizu.Intellect.Account.Agent{slug: slug} -> {slug, "virtual agent"}
    end
  end

  def unpack_audience_list(as_name, record, _context, _field_options) do
    with %{array_agg: entries} <- get_in(record, [Access.key(:__loader__), Access.key(as_name)]),
         true <- is_list(entries) do
      entries = Enum.map(entries, fn({subject, confidence, comment}) ->
        {subject, %{confidence: confidence, comment: comment}}
      end) |> Map.new()
      {:ok, entries}
    else
      _ -> {:error, {:loading, :audience_list}}
    end
  end

  def unpack_responding_to_list(as_name, record, _context, _field_options) do
    with %{array_agg: entries} <- get_in(record, [Access.key(:__loader__), Access.key(as_name)]),
         true <- is_list(entries) do
      entries = Enum.map(entries, fn({subject, confidence, comment}) ->
        {subject, %{confidence: confidence, comment: comment}}
      end) |> Map.new()
      {:ok, entries}
    else
      _ -> {:error, {:loading, :responding_to_list}}
    end
  end

  #---------------------------
  #
  #---------------------------

  #---------------------------
  #
  #---------------------------
  @_defimpl Noizu.Entity.Store.Redis.EntityProtocol
  def as_entity(entity, settings = Noizu.Entity.Meta.Persistence.persistence_settings(table: Noizu.Intellect.Account.Message, store: Noizu.Intellect.Redis), context, options) do
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

  @_defimpl Noizu.Entity.Store.Ecto.EntityProtocol
  def as_entity(entity, settings = Noizu.Entity.Meta.Persistence.persistence_settings(table: Noizu.Intellect.Schema.Account.Message, store: store), context, options) do
    Logger.error("as entity")
    with %{identifier: identifier} <- entity do


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
               left_join: read_status in Noizu.Intellect.Schema.Account.Message.Read,
               on: read_status.message == msg.identifier and read_status.recipient == aud.recipient,
               left_join: content in Noizu.Intellect.Schema.VersionedString,
               on: content.identifier == msg.contents,
               left_join: brief in Noizu.Intellect.Schema.VersionedString,
               on: brief.identifier == msg.brief,
               left_join: meta in Noizu.Intellect.Schema.VersionedString,
               on: meta.identifier == msg.meta,
               left_join: resp in subquery(responding_to),
               on: msg.identifier == resp.message,
               left_join: aud_list in subquery(audience),
               on: msg.identifier == aud_list.message,
               where: msg.identifier == ^identifier,
               limit: 1,
               select: %{msg| __loader__: %{contents: content, brief: brief, responding_to_list: resp, audience_list: aud_list, audience: aud, read_status: read_status}}

      case apply(store, :one, [q]) |> IO.inspect("MESSAGE LOADER") do
        record = %Noizu.Intellect.Schema.Account.Message{} -> from_record(record, settings, context, options)
        _ -> {:error, :not_found}
      end
    end
  end
  def as_entity(entity, settings, context, options) do
    Logger.error("as entity super| #{inspect entity}")
    super(entity, settings, context, options)
  end

  def tag_lookup(tag) do
    f = String.downcase(tag)
    case Noizu.Intellect.Redis.get("tag:#{f}") do
      {:ok, nil} -> nil
      {:ok, id} -> {:ok, String.to_integer(id)}
      _ -> nil
    end
  end

  def cache_tag_lookup(id, tag) do
    f = String.downcase(tag)
    Noizu.Intellect.Redis.set("tag:#{f}", id)
  end

  def insert_tag(tag) do
    # 1. lookup
    q = from q in Noizu.Intellect.Schema.Tag,
        where: q.tag == ^tag,
        limit: 1
    case Noizu.Intellect.Repo.one(q) do
      %Noizu.Intellect.Schema.Tag{identifier: identifier} ->
        cache_tag_lookup(identifier, tag)
        {:ok, identifier}
    _ ->
      %Noizu.Intellect.Schema.Tag{tag: tag}
      |> Noizu.Intellect.Repo.insert()
      |> case do
           {:ok, %Noizu.Intellect.Schema.Tag{identifier: identifier}} ->
             cache_tag_lookup(identifier, tag)
             {:ok, identifier}
           _ -> nil
         end
    end
  end

  def add_summary({:summary, {summary, _action, tags}}, message, context, _options) do
    summary = String.trim(summary)
    unless summary == "" do
      # todo detect existing
      %{message|
        brief: %{title: "Message Summary", body: summary}
      }
      |> Noizu.Intellect.Entity.Repo.update(context)
    end

    # Add Features
    Enum.map(tags || [],
      fn(tag) ->
        tid = tag_lookup(tag)
              |> case do
                   {:ok, id} -> {:ok, id}
                   _ -> insert_tag(tag)
                 end
              |> case do
                   {:ok, id} -> id
                   _ -> nil
                 end
        if tid do
          %Noizu.Intellect.Schema.Message.Tag{
            message: message.identifier,
            tag: tid
          }
          |> Noizu.Intellect.Repo.insert()
        end
      end
    )
  end


  def mark_read(this, recipient, _context, _options) do
    with {:ok, recipient_id} <- Noizu.EntityReference.Protocol.id(recipient) do
      IO.puts "MARK READ #{this.identifier}@#{recipient_id}"
      %Noizu.Intellect.Schema.Account.Message.Read{
        message: this.identifier,
        recipient: recipient_id,
        read_on: DateTime.utc_now()
      } |> Noizu.Intellect.Repo.insert(on_conflict: :replace_all, conflict_target: [:message, :recipient])
    end
  end

  def message_token_size(this, _context, _options) do
    # http://erlport.org/docs/python.html
    # Temp logic we'll eventually want to call a tokenizer lib to determine the true length.
    {:ok, trunc(String.length(this.contents.body || "") / 3)}
  end


  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
    end
  end

  defimpl Inspect do
    def inspect(subject, opts) do
    {:ok, channel} = Noizu.EntityReference.Protocol.sref(subject.channel)
    "#Message<#{subject.identifier}>{
      channel: #{channel},
      contents: #{Inspect.inspect(subject.contents && String.slice(subject.contents.body, 0..64), opts)}
    }"
    end
  end

  defmodule Repo do
    use Noizu.Repo
    import Ecto.Query

    def_repo()


    def __after_get__(entity, context, options) do
      with {:ok, entity} <- super(entity, context, options) do
        with {:ok, m} <- YamlElixir.read_from_string(entity.meta) do
          t = (get_in(entity, [Access.key(:__transient__, %{})]) || %{})
              |> put_in([:raw_meta], entity.meta)
          entity = %{entity| meta: m, __transient__: t}
          {:ok, entity}
        else
        _ -> {:ok, entity}
        end
      end
    end

    def __before_create__(entity, context, options) do
      with {:ok, entity} <- super(entity, context, options),
           {:ok, token_size} <- Noizu.Intellect.Account.Message.message_token_size(entity, context, options) do
        meta = cond do
          x = (entity.__transient__ || %{})[:raw_meta] -> x
          is_bitstring(entity.meta) or is_nil(entity.meta) -> entity.meta
          :else -> Ymlr.document!(entity.meta)
        end
        {:ok, %{entity| token_size: token_size, meta: meta}}
      end
    end

    def __before_update__(entity, context, options) do
      with {:ok, entity} <- super(entity, context, options),
           {:ok, token_size} <- Noizu.Intellect.Account.Message.message_token_size(entity, context, options) do

        meta = cond do
          x = (entity.__transient__ || %{})[:raw_meta] -> x
          is_bitstring(entity.meta) or is_nil(entity.meta) -> entity.meta
          :else -> Ymlr.document!(entity.meta)
        end

        {:ok, %{entity| token_size: token_size, meta: meta}}
      end
    end

    def has_unread?(recipient, channel, _context, _options \\ nil) do
      with {:ok, channel_id} <- Noizu.EntityReference.Protocol.id(channel),
           {:ok, recipient_id} <- Noizu.EntityReference.Protocol.id(recipient) do

        q = from m in Noizu.Intellect.Schema.Account.Message,
                 #join: r in Noizu.Intellect.Schema.Account.Message.Relevancy,
                 #on: r.message == m.identifier,
                 #on: r.recipient == ^recipient_id,
                 left_join: s in Noizu.Intellect.Schema.Account.Message.Read,
                 on: s.message == m.identifier,
                 on: s.recipient == ^recipient_id,
                 where: m.channel == ^channel_id,
                 where: is_nil(s),
                 #where: not is_nil(r),
                 #where: r.relevance >= 50,
                 limit: 1,
                 select: s.message
        case Noizu.Intellect.Repo.all(q) |> IO.inspect(label: "has_unread? #{recipient.slug}@#{channel_id}") do
          [] -> false
          [nil] -> false
          [v] ->
            IO.inspect(v, label: "#{inspect recipient} has UNREAD")
            true
          _ -> false
        end
      end
    end



    def recent_with_status(recipient, channel, context, options \\ nil) do
      with {:ok, channel_id} <- Noizu.EntityReference.Protocol.id(channel),
           {:ok, recipient_id} <- Noizu.EntityReference.Protocol.id(recipient) do

        limit = options[:limit] || 100
        q = from m in Noizu.Intellect.Schema.Account.Message,
                 left_join: s in Noizu.Intellect.Schema.Account.Message.Read,
                 on: s.message == m.identifier,
                 on: s.recipient == ^recipient_id,
                 where: m.channel == ^channel_id,
                 order_by: [desc: m.created_on],
                 limit: ^limit,
                 select: {m, s}
        messages = Enum.map(
                     Noizu.Intellect.Repo.all(q),
                     fn({msg, status}) ->
                       # Temp - load from ecto needed.
                       with {:ok, message} <- Noizu.Intellect.Account.Message.entity(msg.identifier, context) do
                         {:ok, %{message| read_on: status && status.read_on || nil}}
                       end
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


    defimpl Inspect do
      def inspect(subject, opts) do
        ids = Enum.map(subject.entities, & &1.identifier)
        {s_ids,ids} = Enum.split(ids, 5)
        {ids, e_ids} = Enum.split(ids, -5)
        s_covers = Enum.join(s_ids, ",")
        middle = cond do
          length(ids) > 0 -> ",...,"
          :else -> ""
        end
        e_covers = Enum.join(e_ids, ",")
        """
        #Message.Repo<>{
          messages: #{s_covers}#{middle}#{e_covers},
          length: #{subject.length}
        }
        """
      end
    end

  end
end


defimpl Noizu.Intellect.DynamicPrompt, for: [Noizu.Intellect.Account.Message] do
  require Logger

  def message_priority(subject, prompt_context, _context, _options) do
    if prompt_context.agent do
      subject.priority
    end
  end

  def summarize_message(message, priority, prompt_context, _context, options) do
    current_time = options[:current_time] || DateTime.utc_now()
    cond do
      is_nil(message.brief) || is_nil(message.brief.body) -> false
      is_nil(prompt_context.agent) ->
        cond do
          DateTime.compare(Timex.shift(current_time, minutes: -5), message.time_stamp.modified_on) == :lt ->
            message.token_size > 4096
          DateTime.compare(Timex.shift(current_time, minutes: -15), message.time_stamp.modified_on) == :lt ->
            message.token_size > 3000
          DateTime.compare(Timex.shift(current_time, minutes: -30), message.time_stamp.modified_on) == :lt ->
            message.token_size > 2048
          DateTime.compare(Timex.shift(current_time, minutes: -60), message.time_stamp.modified_on) == :lt ->
            message.token_size > 1024
          :else ->
            message.token_size > 512
        end
      DateTime.compare(Timex.shift(current_time, minutes: -15), message.time_stamp.modified_on) == :lt ->
        cond do
          priority < 0.1 -> true
          priority < 0.5 && ((message.token_size || 0) > 512) -> true
          :else -> false
        end
      priority < 0.5 -> true
      :else ->
        # @todo calculate relevancy to new message with secondary systems based on vectors.
        false
    end
  end

  def prompt!(subject, assigns, prompt_context, context, options) do
    with {:ok, prompt} <- prompt(subject, assigns, prompt_context, context, options) do
      prompt
    else
      _ -> ""
    end
  end

  def prompt(subject, assigns, %{format: :markdown} = prompt_context, context, options) do
    {sender_type, sender_slug, sender_name} = case subject.sender do
      %Noizu.Intellect.Account.Member{user: user} -> {"human operator", user.slug, user.name}
      %Noizu.Intellect.Account.Agent{slug: slug, details: %{title: name}} -> {"virtual agent", slug, name}
      _ -> {"other", "other"}
    end

    # @TODO switch to json response body, return in Repo and apply prompt method on repo.
    priority = message_priority(subject, prompt_context, context, options)
    brief = summarize_message(subject, priority, prompt_context, context, options)
    contents = if (brief), do: subject.brief.body || "", else: subject.contents.body || ""

    message = %{message: %{
    id: subject.identifier || "[NEW]",
    sender: "#{subject.sender.identifier} @#{sender_slug} (#{sender_type})",
    sent_on: subject.time_stamp.modified_on,
    contents: contents,
    }}

    prompt = Ymlr.document!(message) |> String.trim_leading("---\n")
    {:ok, prompt}
  end
  def minder!(subject, assigns, prompt_context, context, options) do
    with {:ok, prompt} <- minder(subject, assigns, prompt_context, context, options) do
      prompt
    else
      _ -> ""
    end
  end
  def minder(_subject, _assigns, _prompt_context, _context, _options) do
    prompt = nil
    {:ok, prompt}
  end
end




defimpl Noizu.Intellect.DynamicPrompt, for: [Noizu.Intellect.Account.Message.Repo] do
  require Logger
  def prompt!(subject, assigns, prompt_context, context, options) do
    with {:ok, prompt} <- prompt(subject, assigns, prompt_context, context, options) do
      prompt
    else
      _ -> ""
    end
  end
  def prompt(subject, assigns, prompt_context, _context, _options) do

    slug_lookup = Enum.map(prompt_context.channel_members, fn(member) ->
      case member do
        %{slug: slug} -> {member.identifier, %{slug: slug, type: "virtual agent"}}
        %{user: %{slug: slug}} -> {member.identifier, %{slug: slug, type: "human operator"}}
      end
    end) |> Map.new()

    messages = if prompt_context.agent do
      Enum.map(subject.entities,
        fn(message) ->
          {sender_type, sender_slug, _sender_name} = case message.sender do
            %Noizu.Intellect.Account.Member{user: user} -> {"human", user.slug, user.name}
            %Noizu.Intellect.Account.Agent{slug: slug, details: %{title: name}} -> {"virtual-agent", slug, name}
            _ -> {"other", "other", "other"}
          end
          review? = (message.sender.identifier != prompt_context.agent.identifier) && is_nil(message.answered_by) && (message.priority >= 50) && is_nil(message.read_on) && true || false
          contents = cond do
            review? ->
              message.contents.body
            #message.priority > 60 -> message.contents.body # is related? check
            :else ->
              message.brief && message.brief.body || message.contents.body
          end
          %{
            id: message.identifier,
            contents: contents,
            created_on: message.time_stamp.created_on,
            sender: "#{message.sender.identifier} @#{slug_lookup[message.sender.identifier][:slug] || "???"} (#{slug_lookup[message.sender.identifier][:type] || "virtual agent"})",
            processed?: !is_nil(message.read_on),
            review?: review?,
          }
        end)
      else
        Enum.map(subject.entities,
          fn(message) ->
            {sender_type, sender_slug, _sender_name} = case message.sender do
              %Noizu.Intellect.Account.Member{user: user} -> {"human", user.slug, user.name}
              %Noizu.Intellect.Account.Agent{slug: slug, details: %{title: name}} -> {"virtual-agent", slug, name}
              _ -> {"other", "other", "other"}
            end
            contents = message.brief && message.brief.body || message.contents.body
            %{
              id: message.identifier,
              contents: contents,
              created_on: message.time_stamp.created_on,
              sender: "#{message.sender.identifier} @#{slug_lookup[message.sender.identifier][:slug] || "???"} (#{slug_lookup[message.sender.identifier][:type] || "virtual agent"})",
            }
          end)
    end


    prompt = Ymlr.document!({["Chat History"], %{messages: messages}}) |> String.trim_leading("---\n")
    {:ok, prompt}
  end
  def minder!(subject,  assigns, prompt_context, context, options) do
    with {:ok, prompt} <- minder(subject, assigns, prompt_context, context, options) do
      prompt
    else
      _ -> ""
    end
  end
  def minder(_subject, _assigns, _prompt_context, _context, _options) do
    prompt = nil
    {:ok, prompt}
  end
  def assigns(_, prompt_context, _, _), do: {:ok, prompt_context.assigns}
  def request(_, request, _, _), do: {:ok, request}
end

defimpl Noizu.Intellect.LiveView.Encoder, for: [Noizu.Intellect.Account.Message] do
  def encode!(message, _context, _options \\ nil) do
    {:ok, user_ref} = Noizu.EntityReference.Protocol.ref(message.sender)
    sender = case message.sender do
      %Noizu.Intellect.User{name: name} -> name
      %Noizu.Intellect.Account.Agent{slug: name} -> name
      _ -> "other"
    end

    %Noizu.IntellectWeb.Message{
      identifier: message.identifier,
      type: :message, # Pending
      glyph: nil, # Pending
      typing: false,
      timestamp: message.time_stamp.created_on,
      user_name: sender,
      user: user_ref,
      profile_image: nil,
      mood: message.user_mood,
      body: message.contents.body,
      meta: message.meta,
      state: :sent
    }
  end
end
