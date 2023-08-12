#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.Account do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.Entity.Repo
  import Ecto.Query

  @vsn 1.0
  @sref "account"
  @persistence ecto_store(Noizu.Intellect.Schema.Account, Noizu.Intellect.Repo)
  def_entity do
    identifier :integer
    field :slug, nil
    field :profile_image, nil, Noizu.Entity.VersionedURI
    field :details, nil, Noizu.Entity.VersionedString
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  def channels(this, context) do
    with {:ok, _identifier} <- id(this) do
      q = from account in Noizu.Intellect.Schema.Account,
               join: channel in Noizu.Intellect.Schema.Account.Channel,
               on: account.identifier == channel.account,
               where: is_nil(account.deleted_on),
               where: is_nil(channel.deleted_on),
               select: channel
      case Noizu.Intellect.Repo.all(q) do
        channels when is_list(channels) ->
          channels = channels
                     |> Enum.map(fn(channel) -> Noizu.Intellect.Account.Channel.entity(channel, context) end)
                     |> Enum.map(
                          fn ({:ok, v}) -> v
                            (_) -> nil
                          end ) |> Enum.reject(&is_nil/1)
          {:ok, channels}
        _ -> {:error, :not_found}
      end
    end
  end

  def channel_by_slug(this, slug, context) do
    with {:ok, _identifier} <- id(this) do
      q = from account in Noizu.Intellect.Schema.Account,
               join: channel in Noizu.Intellect.Schema.Account.Channel,
               on: account.identifier == channel.account,
               where: channel.slug == ^slug,
               where: is_nil(account.deleted_on),
               select: channel,
               limit: 1
      case Noizu.Intellect.Repo.all(q) do
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
    def_repo()
  end
end
