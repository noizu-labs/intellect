#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Entity.VersionedString do
  use Noizu.Entities

  @vsn 1.0
  @sref "versioned-string"
  @persistence ecto_store(Noizu.Intellect.Schema.VersionedString, Noizu.Intellect.Repo)
  def_entity do
    identifier :integer
    field :version
    field :title
    field :body
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end
  use Noizu.Entity.Field.Behaviour

  def type__before_create(%__MODULE__{} = this,_,context,options) do
    cond do
      this.identifier -> {:ok, this}
      :else -> Noizu.Intellect.Entity.Repo.create(this,context,options)
    end
  end
  def type__before_create(%{} = settings,_,context,options) do
    entity = %__MODULE__{
      version: 1,
      title: settings[:title] || "",
      body: settings[:body] || "",
      time_stamp: Noizu.Entity.TimeStamp.now()
    }
    Noizu.Intellect.Entity.Repo.create(entity,context,options)
  end
  def type__before_create(body,_,context,options) when is_bitstring(body) do
    entity = %__MODULE__{
      version: 1,
      title: "",
      body: body,
      time_stamp: Noizu.Entity.TimeStamp.now()
    }
    Noizu.Intellect.Entity.Repo.create(entity,context,options)
  end
  def type__before_create(_,_,_,_), do: nil

  defmodule Repo do
    use Noizu.Repo
    def_repo()
  end
end

defimpl Noizu.Entity.Protocol, for: [Noizu.Entity.VersionedString]  do
  def layer_identifier(entity, _layer) do
    {:ok, entity.identifier}
  end
end

defimpl Noizu.Entity.Store.Ecto.Entity.FieldProtocol, for: [Noizu.Entity.VersionedString] do
  require  Noizu.Entity.Meta.Persistence
  require  Noizu.Entity.Meta.Field
  alias Noizu.Entity.Meta
  def as_record(_, _), do: {:error, :not_supported}
  def from_record(_,_), do: {:error, :not_supported}

  def field_as_record(
        field,
        field_settings = Meta.Field.field_settings(name: name, store: field_store),
        persistence_settings = Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    {as_name, field}
  end

  def field_from_record(
        field,
        record,
        Meta.Field.field_settings(name: name, store: field_store),
        Meta.Persistence.persistence_settings(store: store, table: table),
        context,
        options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    case Map.get(record, as_name) do
      ref = {:ref, Noizu.Entity.VersionedString, _} ->
        with {:ok, entity} <- Noizu.Entity.VersionedString.Repo.get(ref, context, options) do
          {name, entity}
        end
      entity = %Noizu.Entity.VersionedString{} -> {name, entity}
      _ -> nil
    end
  end
end
