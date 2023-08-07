#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.Account.Message do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.Entity.Repo
  alias Noizu.Entity.TimeStamp

  @vsn 1.0
  @sref "account-message"
  @persistence ecto_store(Noizu.Intellect.Schema.Account.Message, Noizu.Intellect.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    identifier :integer
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

    field :depth
    field :user_mood #, nil, Noizu.Intellect.Emoji
    field :event #, nil, Noizu.Intellect.Message.Event
    field :token_size
    field :contents, nil, Noizu.Entity.VersionedString
    field :brief, nil, Noizu.Entity.VersionedString
    field :meta, nil, Noizu.Entity.VersionedString
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end
  import Ecto.Query
  require Noizu.Entity.Meta.Persistence


  def unpack_audience_list(as_name, record, context, field_options) do
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

  def unpack_responding_to_list(as_name, record, context, field_options) do
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
  @defimpl Noizu.Entity.Store.Ecto.EntityProtocol
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
               select: %{msg| __loader__: %{contents: content, brief: brief, meta: meta, responding_to_list: resp, audience_list: aud_list, audience: aud, read_status: read_status}}

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

  def add_summary({:summary, {summary, features}}, message, context, options) do
    summary = String.trim(summary)
    unless summary == "" do
      # todo detect existing
      %{message|
        brief: %{title: "Message Summary", body: summary}
      }
      |> Noizu.Intellect.Entity.Repo.update(context)
    end
    # Logger.error("[TODO] populate message features #{inspect features, pretty: true}")
  end

  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
    end
  end

  def mark_read(this, recipient, context, options) do
    with {:ok, recipient_id} <- Noizu.EntityReference.Protocol.id(recipient) do
      IO.puts "MARK READ #{this.identifier}@#{recipient_id}"
      %Noizu.Intellect.Schema.Account.Message.Read{
        message: this.identifier,
        recipient: recipient_id,
        read_on: DateTime.utc_now()
      } |> Noizu.Intellect.Repo.insert(on_conflict: :replace_all, conflict_target: [:message, :recipient])
    end
  end

  def message_token_size(this, context, options) do
    # http://erlport.org/docs/python.html
    # Temp logic we'll eventually want to call a tokenizer lib to determine the true length.
    {:ok, trunc(String.length(this.contents.body || "") / 3)}
  end

  defmodule Repo do
    use Noizu.Repo
    alias Noizu.Intellect.User.Credential
    alias Noizu.Intellect.User.Credential.LoginPass
    alias Noizu.Intellect.Entity.Repo, as: EntityRepo
    alias Noizu.EntityReference.Protocol, as: ERP
    import Ecto.Query

    def_repo()

    def __before_create__(entity, context, options) do
      with {:ok, entity} <- super(entity, context, options),
           {:ok, token_size} <- Noizu.Intellect.Account.Message.message_token_size(entity, context, options) do
        {:ok, %{entity| token_size: token_size}}
      end
    end

    def __before_update__(entity, context, options) do
      with {:ok, entity} <- super(entity, context, options),
           {:ok, token_size} <- Noizu.Intellect.Account.Message.message_token_size(entity, context, options) do
        {:ok, %{entity| token_size: token_size}}
      end
    end

    def has_unread?(recipient, channel, context, options \\ nil) do
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

  end
end


defimpl Noizu.Intellect.Prompt.DynamicContext.Protocol, for: [Noizu.Intellect.Account.Message] do
  require Logger

  def message_priority(subject, prompt_context, context, options) do
    if prompt_context.agent do
      subject.priority
    end
  end

  def summarize_message(message, priority, prompt_context, context, options) do
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



  def prompt(subject, %{format: :markdown} = prompt_context, context, options) do
    {sender_type, sender_slug, sender_name} = case subject.sender do
      %Noizu.Intellect.Account.Member{user: user} -> {"human", user.slug, user.name}
      %Noizu.Intellect.Account.Agent{slug: slug, details: %{title: name}} -> {"virtual-agent", slug, name}
      _ -> {"other", "other"}
    end

    # @TODO switch to json response body, return in Repo and apply prompt method on repo.

    current_time = options[:current_time] || DateTime.utc_now()
    priority = message_priority(subject, prompt_context, context, options)
    brief = summarize_message(subject, priority, prompt_context, context, options)
    contents = if (brief), do: subject.brief.body || "", else: subject.contents.body || ""
    prompt =
      """
        # Message
        - id: #{subject.identifier || "[NEW]"}
          processed: #{subject.read_on && "true" || "false"}
          priority: #{priority}
          message_brief: #{brief && true || false}
          sender:
            id: #{subject.sender.identifier}
            type: #{sender_type}
            slug: #{sender_slug}
            name: #{sender_name}
          sent-on: "#{subject.time_stamp.modified_on}"
          contents: |-1
           #{String.split(contents, "\n") |> Enum.join("\n     ")}
      """
    {:ok, prompt}
  end
  def minder(subject, prompt_context, context, options) do
    prompt = nil
    {:ok, prompt}
  end
end


defimpl Noizu.Intellect.LiveView.Encoder, for: [Noizu.Intellect.Account.Message] do
  def encode!(message, context, options \\ nil) do
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
      mood: nil,
      body: message.contents.body,
      state: :sent
    }
  end
end
