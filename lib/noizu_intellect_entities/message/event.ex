#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.Message.Event do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.Entity.Repo

  @vsn 1.0
  @sref "message-event"
  @persistence ecto_store(Noizu.Intellect.Schema.Message.Event, Noizu.Intellect.Repo)
  def_entity do
    identifier :integer
    field :details, nil, Noizu.Entity.VersionedString
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
  end
end
