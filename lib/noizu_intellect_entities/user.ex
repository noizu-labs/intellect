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

  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
    end
  end


  defmodule Repo do
    use Noizu.Repo
    def_repo()

    @doc """
    @todo Handle Terms version agreed to.
    """
    def register(name, context, options) do
      %Noizu.Intellect.User{
        name: name,
        time_stamp: Noizu.Entity.TimeStamp.now()
      } |> Noizu.Intellect.Entity.Repo.create(context, options)
    end

    def register_with_login(name, email, password, context, options) do
      with {:ok, user} <- register(name, context, options),
           {:ok, _login} <- Noizu.Intellect.User.Credential.Repo.register_login(user, email, password, context, options) do
        {:ok, user}
      end
    end
  end

end
