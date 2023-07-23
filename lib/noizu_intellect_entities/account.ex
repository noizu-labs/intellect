#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.Account do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.Entity.Repo
  alias Noizu.Entity.TimeStamp
  import Ecto.Query

  @vsn 1.0
  @sref "account"
  @persistence ecto_store(Noizu.Intellect.Schema.Account, Noizu.Intellect.Repo)
  def_entity do
    identifier :integer
    field :slug, nil
    field :details, nil, Noizu.Entity.VersionedString
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  def channel_by_slug(this, slug, context) do
    with {:ok, identifier} <- id(this) do
      q = from account in Noizu.Intellect.Schema.Account,
               join: channel in Noizu.Intellect.Schema.Account.Channel,
               on: account.identifier == channel.account,
               where: channel.slug == ^slug,
               where: is_nil(account.deleted_on),
               select: channel,
               limit: 1
      case Noizu.Intellect.Repo.all(q) |> IO.inspect(label: "Query") do
        [channel] ->
          # Todo extend entity to support from_record here.
          with {:ok, channel} <- Noizu.Intellect.Account.Channel.entity(channel.identifier, context) do
            {:ok, channel}
          end
        _ -> {:error, :not_found}
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
    alias Noizu.Intellect.User.Credential
    alias Noizu.Intellect.User.Credential.LoginPass
    alias Noizu.Intellect.Entity.Repo, as: EntityRepo
    alias Noizu.EntityReference.Protocol, as: ERP
    def_repo()
  end
end
