defmodule Noizu.Intellect.Services.ConfigurationProvider do
  @behaviour Noizu.Service.NodeManager.ConfigurationManagerBehaviour
  require Noizu.Service.NodeManager.ConfigurationManagerBehaviour
  import Noizu.Service.NodeManager.ConfigurationManagerBehaviour


  def cache(contents), do: contents
  def cache(_, contents), do: contents

  def cached(), do: configuration()
  def cached(node), do: configuration(node)

  def configuration(node) do
    _service_config = node_service(
      pool: Noizu.Intellect.Service.VirtualService,
      node: node,
      priority: 0,
      supervisor_target: target_window(target: 3, low: 1, high: 5),
      worker_target: target_window(target: 100, low: 25, high: 250)
    )
    _service_ingestion_config = node_service(
      pool: Noizu.Intellect.Service.VirtualService.Ingestion,
      node: node,
      priority: 0,
      supervisor_target: target_window(target: 3, low: 1, high: 5),
      worker_target: target_window(target: 100, low: 25, high: 250)
    )
    agent_config = node_service(
      pool: Noizu.Intellect.Service.Agent,
      node: node,
      priority: 0,
      supervisor_target: target_window(target: 3, low: 1, high: 5),
      worker_target: target_window(target: 100, low: 25, high: 250)
    )
    agent_ingestion_config = node_service(
      pool: Noizu.Intellect.Service.Agent.Ingestion,
      node: node,
      priority: 0,
      supervisor_target: target_window(target: 3, low: 1, high: 5),
      worker_target: target_window(target: 100, low: 25, high: 250)
    )
    _agent_monitor_config = node_service(
      pool: Noizu.Intellect.Service.Agent.Monitor,
      node: node,
      priority: 0,
      supervisor_target: target_window(target: 3, low: 1, high: 5),
      worker_target: target_window(target: 100, low: 25, high: 250)
    )
    _agent_memory_config = node_service(
      pool: Noizu.Intellect.Service.Agent.Memory,
      node: node,
      priority: 0,
      supervisor_target: target_window(target: 3, low: 1, high: 5),
      worker_target: target_window(target: 100, low: 25, high: 250)
    )
    _messenger_config = node_service(
      pool: Noizu.Intellect.Service.Messenger,
      node: node,
      priority: 0,
      supervisor_target: target_window(target: 3, low: 1, high: 5),
      worker_target: target_window(target: 100, low: 25, high: 250)
    )
    %{
      #Noizu.Intellect.Service.VirtualService => service_config,
      #Noizu.Intellect.Service.VirtualService.Ingestion => service_ingestion_config,
      Noizu.Intellect.Service.Agent => agent_config,
      Noizu.Intellect.Service.Agent.Ingestion => agent_ingestion_config,
      #Noizu.Intellect.Service.Agent.Monitor => agent_monitor_config,
      #Noizu.Intellect.Service.Agent.Memory => agent_memory_config,
      #Noizu.Intellect.Service.Messenger => messenger_config,
    }
    |> then(&({:ok, &1}))
  end

  def configuration() do
    n = node()
    _service_config = cluster_service(
      pool: Noizu.Intellect.Service.VirtualService,
      priority: 1,
      node_target: target_window(target: 1, low: 0, high: 2),
      worker_target: target_window(target: 100, low: 25, high: 250)
    )
    _service_ingestion_config = cluster_service(
      pool: Noizu.Intellect.Service.VirtualService.Ingestion,
      priority: 1,
      node_target: target_window(target: 1, low: 0, high: 2),
      worker_target: target_window(target: 100, low: 25, high: 250)
    )
    agent_config = cluster_service(
      pool: Noizu.Intellect.Service.Agent,
      priority: 1,
      node_target: target_window(target: 1, low: 0, high: 2),
      worker_target: target_window(target: 100, low: 25, high: 250)
    )
    agent_ingestion_config = cluster_service(
      pool: Noizu.Intellect.Service.Agent.Ingestion,
      priority: 1,
      node_target: target_window(target: 1, low: 0, high: 2),
      worker_target: target_window(target: 100, low: 25, high: 250)
    )
    _agent_memory_config = cluster_service(
      pool: Noizu.Intellect.Service.Agent.Memory,
      priority: 1,
      node_target: target_window(target: 1, low: 0, high: 2),
      worker_target: target_window(target: 100, low: 25, high: 250)
    )
    _agent_monitor_config = cluster_service(
      pool: Noizu.Intellect.Service.Agent.Monitor,
      priority: 1,
      node_target: target_window(target: 1, low: 0, high: 2),
      worker_target: target_window(target: 100, low: 25, high: 250)
    )
    _messenger_config = cluster_service(
      pool: Noizu.Intellect.Service.Messenger,
      priority: 1,
      node_target: target_window(target: 1, low: 0, high: 2),
      worker_target: target_window(target: 100, low: 25, high: 250)
    )
    cluster = %{
      n =>  (configuration(n) |> elem(1))
    }

    %{
#      Noizu.Intellect.Service.VirtualService =>
#      %{
#        cluster: service_config,
#        nodes: %{
#          n => cluster[n][Noizu.Intellect.Service.VirtualService],
#        }
#      },
#      Noizu.Intellect.Service.VirtualService.Ingestion =>
#      %{
#        cluster: service_ingestion_config,
#        nodes: %{
#          n => cluster[n][Noizu.Intellect.Service.VirtualService.Ingestion],
#        }
#      },
      Noizu.Intellect.Service.Agent =>
      %{
        cluster: agent_config,
        nodes: %{
          n => cluster[n][Noizu.Intellect.Service.Agent],
        }
      },
      Noizu.Intellect.Service.Agent.Ingestion =>
      %{
        cluster: agent_ingestion_config,
        nodes: %{
          n => cluster[n][Noizu.Intellect.Service.Agent.Ingestion],
        }
      },
#      Noizu.Intellect.Service.Agent.Memory =>
#      %{
#        cluster: agent_memory_config,
#        nodes: %{
#          n => cluster[n][Noizu.Intellect.Service.Agent.Memory],
#        }
#      },
#      Noizu.Intellect.Service.Agent.Monitor =>
#      %{
#        cluster: agent_monitor_config,
#        nodes: %{
#          n => cluster[n][Noizu.Intellect.Service.Agent.Monitor],
#        }
#      },
#      Noizu.Intellect.Service.Messenger =>
#      %{
#        cluster: messenger_config,
#        nodes: %{
#          n => cluster[n][Noizu.Intellect.Service.Messenger],
#        }
#      }
    }
    |> then(&({:ok, &1}))

  end
end
