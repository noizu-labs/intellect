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
           wake!(agent_identifier, context)
         end
       )
    :ok
  end

end
