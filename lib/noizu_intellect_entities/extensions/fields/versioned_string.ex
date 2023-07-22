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

  def id(id) when is_integer(id), do: {:ok, id}
  def id(R.ref(module: __MODULE__, identifier: id)), do: {:ok, id}
  def id(%__MODULE__{} = this), do: {:ok, this.identifier}

  #----------------
  #
  #----------------
  def kind(id) when is_integer(id), do: {:ok, __MODULE__}
  def kind(R.ref(module: __MODULE__, identifier: id)), do: {:ok, __MODULE__}
  def kind(%__MODULE__{} = this), do: {:ok, __MODULE__}

  def ref(id) when is_integer(id), do: {:ok, R.ref(module: __MODULE__, identifier: id)}
  def ref(R.ref(module: __MODULE__, identifier: _) = ref), do: {:ok, ref}
  def ref(%__MODULE__{} = this), do: {:ok, R.ref(module: __MODULE__, identifier: this.identifier)}

  #------------------------
  #
  #------------------------
  def entity(subject, context)
  def entity(id, _) when is_integer(id) do
    # temp logic.
    if record = Noizu.Intellect.Repo.get(Noizu.Intellect.Schema.VersionedString, id) do
      from_record(record)
    else
      {:error, :not_found}
    end
  end
  def entity(R.ref(module: __MODULE__, identifier: id), context), do: entity(id, context)
  def entity(%__MODULE__{} = this, context), do: {:ok, this}

  #------------------------
  #
  #------------------------
  def from_record(record) do
    e = %__MODULE__{
      identifier: record.identifier,
      version: record.version,
      title: record.title,
      body: record.body,
      time_stamp: %Noizu.Entity.TimeStamp{
        created_on: record.created_on,
        modified_on: record.modified_on,
        deleted_on: record.deleted_on,
      }
    }
    {:ok, e}
  end

  def type_as_entity(this, _, _), do: {:ok, this}
  def stub, do: {:ok, %__MODULE__{}}

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

defimpl Noizu.Entity.Store.Ecto.Protocol, for: [Noizu.Entity.VersionedString] do
  require  Noizu.Entity.Meta.Persistence
  require  Noizu.Entity.Meta.Field
  alias Noizu.Entity.Meta
  def as_record(_, _), do: {:error, :not_supported}
  def from_record(_,_), do: {:error, :not_supported}

  def field_as_record(
        field,
        field_settings = Meta.Field.field_settings(name: name, store: field_store),
        persistence_settings = Meta.Persistence.persistence_settings(store: store, table: table)
      ) do
    IO.inspect(field, label: "[VersionedString.field]")
    IO.inspect(field_settings, label: "[VersionedString.field_settings]")
    IO.inspect(persistence_settings, label: "[VersionedString.persistence_settings]")
#    name = field_store[table][:name] || field_store[store][:name] || name
#
#    # We need to do a universal ecto conversion
#    with {:ok, id} <- Noizu.EntityReference.Protocol.id(field) do
#      {name, id}
#    end
    {:error, :pending}
  end

  def field_from_record(_, record, Meta.Field.field_settings(name: name, store: field_store), Meta.Persistence.persistence_settings(store: store, table: table)) do
    {:error, :pending}
  end
end
