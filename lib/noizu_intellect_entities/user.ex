#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.User do
  use Noizu.Entities
  import Ecto.Query

  @vsn 1.0
  @sref "user"
  @persistence ecto_store(Noizu.Intellect.Schema.User, Noizu.Intellect.Repo)
  @derive Ymlr.Encoder
  def_entity do
    identifier :integer
    field :slug
    field :name
    field :profile_image, nil, Noizu.Entity.VersionedURI
    field :response_preferences, nil, Noizu.Entity.VersionedString
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
    end
  end

  def default_project(active_user, context, _options \\ nil) do
    with {:ok, identifier} <- id(active_user) do
      q = from account in Noizu.Intellect.Schema.Account,
               join: member in Noizu.Intellect.Schema.Account.Member,
               on: account.identifier == member.account,
               join: user in Noizu.Intellect.Schema.User,
               on: member.user == user.identifier,
               where: user.identifier == ^identifier,
               where: is_nil(member.deleted_on),
               order_by: member.created_on,
               select: {account, member},
               limit: 1
      case Noizu.Intellect.Repo.all(q) do
        [{account, member}] ->
        # Todo extend entity to support from_record here.
          with {:ok, account} <- Noizu.Intellect.Account.entity(account.identifier, context),
               {:ok, member} <- Noizu.Intellect.Account.Member.entity(member.identifier, context) do
            {:ok, {account, member}}
          end
          _ -> {:error, :not_found}
      end
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
