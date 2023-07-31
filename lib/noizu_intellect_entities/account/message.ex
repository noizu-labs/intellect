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
  def_entity do
    identifier :integer
    field :sender, nil, Noizu.Entity.Reference
    field :channel, nil, Noizu.Entity.Reference
    field :read_on
    field :depth
    field :relevancy_map, []
    field :user_mood #, nil, Noizu.Intellect.Emoji
    field :event #, nil, Noizu.Intellect.Message.Event
    field :contents, nil, Noizu.Entity.VersionedString
    field :brief, nil, Noizu.Entity.VersionedString
    field :meta, nil, Noizu.Entity.VersionedString
    field :time_stamp, nil, Noizu.Entity.TimeStamp
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

  defmodule Repo do
    use Noizu.Repo
    alias Noizu.Intellect.User.Credential
    alias Noizu.Intellect.User.Credential.LoginPass
    alias Noizu.Intellect.Entity.Repo, as: EntityRepo
    alias Noizu.EntityReference.Protocol, as: ERP
    import Ecto.Query

    def_repo()

    def __after_get__(entity, _, _) do
      if entity do
          q = from r in Noizu.Intellect.Schema.Account.Message.Relevancy,
              where: r.message == ^entity.identifier,
              select: r
          rm = Noizu.Intellect.Repo.all(q)
               |> Enum.map(
                    fn(rel) ->
                      with {:ok, id} <- Noizu.EntityReference.Protocol.id(rel.recipient) do
                        responding_to = case Noizu.Intellect.Account.Message.id(rel.responding_to) do
                          {:ok, id} -> id
                          _ -> nil
                        end

                        {id, %{responding_to: responding_to, comment: rel.comment, relevancy: rel.relevance / 100.00 }}
                      end
                    end
                  )
          {:ok, %{entity| relevancy_map: rm}}
      else
        {:ok, entity}
      end
    end



    def has_unread?(recipient, channel, context, options \\ nil) do
      with {:ok, channel_id} <- Noizu.EntityReference.Protocol.id(channel),
           {:ok, recipient_id} <- Noizu.EntityReference.Protocol.id(recipient) do

        q = from m in Noizu.Intellect.Schema.Account.Message,
                 join: r in Noizu.Intellect.Schema.Account.Message.Relevancy,
                 on: r.message == m.identifier,
                 on: r.recipient == ^recipient_id,
                 left_join: s in Noizu.Intellect.Schema.Account.Message.Read,
                 on: s.message == r.message,
                 on: s.recipient == r.recipient,
                 where: m.channel == ^channel_id,
                 where: is_nil(s),
                 where: not is_nil(r),
                 where: r.relevance >= 50,
                 limit: 1,
                 select: r.message
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
  def prompt(subject, %{format: :markdown} = prompt_context, context, options) do
    {sender_type, sender_slug, sender_name} = case subject.sender do
      %Noizu.Intellect.Account.Member{user: user} -> {"human", user.slug, user.name}
      %Noizu.Intellect.Account.Agent{slug: slug, details: %{title: name}} -> {"virtual-agent", slug, name}
      _ -> {"other", "other"}
    end

    r = Enum.map(subject.relevancy_map || [],
          fn({id,rel}) ->
            """
             - for-user: #{id}
               for-message: #{rel.responding_to}
               value: #{rel.relevancy}
               comment: |-1
                #{String.split(rel.comment || "", "\n") |> Enum.join("\n    ")}
            """
          end)
        |> Enum.join("\n")
    relevancy = case r do
      nil -> ""
      "" -> ""
      "\n" -> ""
      r ->
        """
        relevance:
         #{r}
        """
    end

    priority = if prompt_context.agent do
      with {:ok, agent_id} <- Noizu.EntityReference.Protocol.id(prompt_context.agent) do
        with {_, rel} <- Enum.find_value(subject.relevancy_map || {}, fn(x = {id, _}) -> id == agent_id && x || nil end) do
          rel.relevancy
        end
      end
    end || 0.0

    prompt = """
    ````````````msg
    msg:
      id: #{subject.identifier || "[NEW]"}
      processed: #{subject.read_on && "true" || "false"}
      priority: #{priority}
      sender:
        id: #{subject.sender.identifier}
        type: #{sender_type}
        slug: #{sender_slug}
        name: #{sender_name}
      sent-on: "#{subject.time_stamp.modified_on}"
      contents: |-1
       #{String.split(subject.contents.body || "", "\n") |> Enum.join("\n   ")}
    ````````````
    """

    if (is_nil(subject.read_on) && prompt_context.agent), do: Logger.error("#{prompt_context.agent.slug}:" <> prompt)
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
