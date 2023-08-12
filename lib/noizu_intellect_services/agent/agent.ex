defmodule Noizu.Intellect.Service.Agent do
  use Noizu.Service
  import Ecto.Query
  Noizu.Service.Server.default()
  require Logger

  def bring_workers_online(context) do
    Logger.error("WAKING")
    (from a in Noizu.Intellect.Schema.Account.Agent,
          select: a.identifier)
    |> Noizu.Intellect.Repo.all()
    |> Enum.map(
         fn(agent_identifier) ->
           with {:ok, ref} <- Noizu.Intellect.Account.Agent.ref(agent_identifier),
                {:ok, ref} <- Noizu.Intellect.Service.Agent.Worker.ref(ref)
             do
             wake!(ref, context)
           end
         end
       )
    :ok
  end

end
