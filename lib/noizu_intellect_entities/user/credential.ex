#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.User.Credential do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.User.Credential
  alias Noizu.Intellect.Entity.Repo
  alias Noizu.Entity.TimeStamp

  @vsn 1.0
  @sref "credential"
  @persistence ecto_store(Noizu.Intellect.Schema.User.Credential, Noizu.Intellect.Repo)
  def_entity do
    identifier :integer
    @store [name: :user_id]
    field :user, nil, Noizu.Entity.Reference

    @store [name: :details_id]
    field :details, nil, Noizu.Entity.VersionedString

    field :type

    field :details, nil

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
    def_repo()


    def register_login(user, login, pass, context, options) do
      now = options[:current_time] || DateTime.utc_now()
      with {:ok, credential} <- %Credential{
                                  user: user,
                                  type: :login,
                                  details: %{title: "Login", body: "Default Login"},
                                  time_stamp: TimeStamp.now(now)
                                } |> create(context, options),
           {:ok, credential} <- ERP.ref(credential) do
        Login.Repo.add_login(credential, login, pass, context, options)
      end
    end
  end
end
