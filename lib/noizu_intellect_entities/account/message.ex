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
    field :user_mood #, nil, Noizu.Intellect.Emoji
    field :event #, nil, Noizu.Intellect.Message.Event
    field :contents, nil, Noizu.Entity.VersionedString
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
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
  def prompt(subject, %{format: :markdown} = prompt_context, context, options) do
    sender = case subject.sender do
      %Noizu.Intellect.User{name: name} -> "human: #{name}"
      %Noizu.Intellect.Account.Agent{slug: name} -> "virtual-persona: #{name}"
      _ -> "other"
    end

    prompt = """
    ## 📩
    id: #{subject.identifier}
    read: #{subject.read_on && "true" || "false"}
    from: #{sender}
    time: #{subject.time_stamp.modified_on}
    body:
    #{subject.contents.body}
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
