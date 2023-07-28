#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.Intellect.Services.Supervisor do
  use Supervisor
  require Logger

  def spec(context, options \\ nil) do
    %{
      id: __MODULE__,
      type: :supervisor,
      start: {__MODULE__, :start_link, [context, options]}
    }
  end

  def start_link(context, options \\ nil) do
    Supervisor.start_link(__MODULE__, {context, options}, [{:name, __MODULE__}])
  end

  # supervisor callback
  def init({_context, _options}) do
    context = Noizu.Context.system()
    master? = Application.get_env(:noizu_intellect, :noizu_labs_services, %{})[:master_node] || false
    master_specific = master? && [Noizu.Service.ClusterManager.spec(context)] || []
    standard = [Noizu.Service.NodeManager.spec(context)]
    children = master_specific ++ standard
    Supervisor.init(
      children,
      [
        {:strategy, :one_for_one},
        {:restart, :permanent},
        {:max_restarts, 25000},
        {:max_seconds, 1}
      ])
  end

  def bring_online(context) do
    Noizu.Service.NodeManager.bring_online(node(), context)
  end

end
