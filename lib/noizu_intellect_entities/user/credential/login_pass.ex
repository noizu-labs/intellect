#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.User.Credential.LoginPass do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.User.Credential
  alias Noizu.Intellect.Entity.Repo

  @vsn 1.0
  @sref "credential"
  @persistence ecto_store(Noizu.Intellect.Schema.User.Credential.LoginPass, Noizu.Intellect.Repo)
  def_entity do
    identifier :integer
    field :login
    field :password
  end

  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
    end
  end

  defmodule Repo do
    use Noizu.Repo
    alias Noizu.EntityReference.Protocol, as: ERP

    def_repo()


    def add_login(credential, login, password, context, options) do
      _now = options[:current_time] || DateTime.utc_now()
      with {:ok, identifier} <- ERP.id(credential) do
        %Noizu.Intellect.User.Credential.LoginPass{
          identifier: identifier,
          login: login,
          password: Bcrypt.hash_pwd_salt(password),
        } |> Noizu.Intellect.Entity.Repo.create(context, options)
      end
    end
  end
end
