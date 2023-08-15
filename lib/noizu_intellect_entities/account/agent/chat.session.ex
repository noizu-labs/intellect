#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.Account.Agent.Chat.Session do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.Entity.Repo

  @vsn 1.0
  @sref "agent-session"
  @persistence redis_store(Noizu.Intellect.Account.Agent.Chat.Session, Noizu.Intellect.Redis)
  @persistence ecto_store(Noizu.Intellect.Schema.Account.Agent.Chat.Session, Noizu.Intellect.Repo)
  @derive Noizu.Entity.Store.Redis.EntityProtocol
  @derive Noizu.Entity.Store.Ecto.EntityProtocol

  def_entity do
    identifier :integer
    field :agent, nil, Noizu.Entity.Reference
    field :member, nil, Noizu.Entity.Reference
    #field :channel, nil, Noizu.Entity.Reference
    field :details, nil, Noizu.Entity.VersionedString
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end
  import Ecto.Query
  require Noizu.Entity.Meta.Persistence

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
                  ) |> IO.inspect(label: "CACHE LOOKUP") do
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

  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
    end
  end

  defmodule Repo do
    use Noizu.Repo
    import Ecto.Query

    def_repo()

    def sessions(agent, member, context, options \\ nil) do
      with {:ok, agent_id} <- Noizu.EntityReference.Protocol.id(agent),
           {:ok, member_id} <- Noizu.EntityReference.Protocol.id(member)
        do
        q = from s in Noizu.Intellect.Schema.Account.Agent.Chat.Session,
                 join: d in Noizu.Intellect.Schema.VersionedString,
                 on: d.identifier == s.details,
                 where: s.agent == ^agent_id,
                 where: s.member == ^member_id,
                 where: is_nil(s.deleted_on),
                 select: %{s| __loader__: %{details: d}}
        case Noizu.Intellect.Repo.all(q) do
          v when is_list(v) ->
            Enum.map(v, fn(s) ->
              with {:ok, session} <- Noizu.Intellect.Account.Agent.Chat.Session.entity(s, context) do
                session
              else
                _ -> nil
              end
            end)
            |> Enum.reject(&is_nil/1)
          _ -> []
        end
        else
        _ -> []
      end


    end

  end
end
