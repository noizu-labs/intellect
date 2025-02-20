#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.Account.Agent.Reminder do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.Entity.Repo

  @vsn 1.0
  @sref "agent-reminder"
  @persistence redis_store(Noizu.Intellect.Account.Agent.Reminder, Noizu.Intellect.Redis)
  @persistence ecto_store(Noizu.Intellect.Schema.Account.Agent.Reminder, Noizu.Intellect.Repo)
  @derive Noizu.Entity.Store.Redis.EntityProtocol
  #@derive Noizu.Entity.Store.Ecto.EntityProtocol

  def_entity do
    identifier :integer
    field :agent, nil, Noizu.Entity.Reference
    field :parent, nil, Noizu.Entity.Reference
    field :name
    field :brief
    field :type
    field :digest
    field :condition
    field :condition_met
    field :instructions

    field :remind_after
    field :remind_until
    field :repeat

    field :condition_checked_on
    field :sent_on
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
  def as_entity(entity, settings = Noizu.Entity.Meta.Persistence.persistence_settings(table: Noizu.Intellect.Account.Agent.Reminder, store: Noizu.Intellect.Redis), context, options) do
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

  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
    end
  end

  defmodule Repo do
    use Noizu.Repo
    import Ecto.Query

    def_repo()

  end
end
