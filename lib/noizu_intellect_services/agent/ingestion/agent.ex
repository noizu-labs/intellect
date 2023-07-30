defmodule Noizu.Intellect.Service.Agent.Ingestion do
  use Noizu.Service
  Noizu.Service.Server.default()
  import Ecto.Query
  require Logger
  alias Noizu.EntityReference.Protocol, as: ERP


  def bring_workers_online(context) do
    Logger.error("WAKING - 2")
    (from a in Noizu.Intellect.Schema.Account.Channel.Agent,
          order_by: [desc: a.agent],
          select: {a.agent, a.channel}
      )
    |> Noizu.Intellect.Repo.all()
    |> Enum.map(
         fn({agent_identifier, channel_identifier}) ->
           with {:ok, agent} <- ERP.ref(agent_identifier),
                {:ok, channel} <- ERP.ref(channel_identifier) do
             wake!({agent, channel}, context)
           end
         end
       )
    :ok
  end

end
