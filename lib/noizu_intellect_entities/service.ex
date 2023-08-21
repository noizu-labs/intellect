#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.Service do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.Entity.Repo

  @vsn 1.0
  @sref "service"

  @persistence redis_store(Noizu.Intellect.Service, Noizu.Intellect.Redis)
  @persistence ecto_store(Noizu.Intellect.Schema.Service, Noizu.Intellect.Repo)
  @derive Noizu.Entity.Store.Redis.EntityProtocol
  @derive Ymlr.Encoder
  def_entity do
    identifier :integer
    field :slug
    field :prompt, nil, Noizu.Entity.VersionedString
    field :minder, nil, Noizu.Entity.VersionedString
    field :details, nil, Noizu.Entity.VersionedString
    field :type
    field :settings
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  #---------------------------
  #
  #---------------------------
  @_defimpl Noizu.Entity.Store.Redis.EntityProtocol
  def as_entity(entity, settings = Noizu.Entity.Meta.Persistence.persistence_settings(table: Noizu.Intellect.Service, store: Noizu.Intellect.Redis), context, options) do
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
  def as_entity(entity, settings, context, options) do
    super(entity, settings, context, options)
  end

  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
    end
  end

  defmodule Repo do
    use Noizu.Repo
    def_repo()
    import Ecto.Query

    def by_slug(slug, context) do
        q = from service in Noizu.Intellect.Schema.Service,
                 where: service.slug == ^slug,
                 where: is_nil(service.deleted_on),
                 select: service
        case Noizu.Intellect.Repo.all(q) do
          [service|_] ->
            # Todo extend entity to support from_record here.
            with {:ok, service} <- Noizu.Intellect.Service.entity(service.identifier, context) do
              {:ok, service}
            end
          _ -> {:error, :not_found}
        end
    end
  end
end
