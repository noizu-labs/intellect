#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.User do
  use Noizu.Entities

  @vsn 1.0
  @sref "user"
  @persistence ecto_store(Noizu.Intellect.Schema.User, Noizu.Intellect.Repo)
  def_entity do
    identifier :integer
    field :name
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
    if record = Noizu.Intellect.Repo.get(Noizu.Intellect.Schema.User, id) do
      from_record(record)
    else
      {:error, :not_found}
    end
  end
  def entity(R.ref(module: __MODULE__, identifier: id), context), do: entity(id, context)
  def entity(%__MODULE__{} = this, context), do: entity(this.identifier, context)


  def from_record(record) do
    e = %__MODULE__{
      identifier: record.identifier,
      name: record.name,
      time_stamp: %Noizu.Entity.TimeStamp{
        created_on: record.created_on,
        modified_on: record.modified_on,
        deleted_on: record.deleted_on,
      }
    }
    {:ok, e}
  end

  def entity(id, _) when is_integer(id) do
    # temp logic.
    if record = Noizu.Intellect.Repo.get(Noizu.Intellect.Schema.User, id) do
      from_record(record)
    else
      {:error, :not_found}
    end
  end

  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
    end
  end


  defmodule Repo do
    use Noizu.Repo
    def_repo()
#
#    def register(name, context, options) do
#      %Noizu.Intellect.User{
#        name: name,
#        last_terms: DateTime.utc_now(),
#        time_stamp: Noizu.Entity.TimeStamp.now()
#      } |> Noizu.Intellect.Entity.Repo.create(context, options)
#    end
#
#    def register_with_login(name, email, password, context, options) do
#      with {:ok, user} <- register(name, context, options),
#           {:ok, _login} <- Noizu.Intellect.Credential.add_login(user, email, password, context, options) do
#        {:ok, user}
#      end
#    end

  end

end
