defmodule Noizu.Intellect.Service.Agent.Ingestion.Worker do
  use Noizu.Entities
  require Noizu.Service.Types
  import Ecto.Query

  @vsn 1.0
  @sref "worker-agent"
  @persistence redis_store(Noizu.Intellect.Service.Agent.Ingestion.Worker, Noizu.Intellect.Redis)
  def_entity do
    identifier :dual_ref
    field :agent, nil, Noizu.Entity.Reference
    field :account, nil, Noizu.Entity.Reference
    field :channel, nil, Noizu.Entity.Reference
    field :book_keeping, %{}
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end
  use Noizu.Service.Worker.Behaviour

  #-------------------
  #
  #-------------------
  def init(R.ref(module: __MODULE__, identifier: identifier), _args, _context) do
    %__MODULE__{
      identifier: identifier,
    }
  end

  #-------------------
  #
  #-------------------

  #-------------------
  #
  #-------------------

  #-------------------
  #
  #-------------------
  def load(state, context), do: load(state, context, nil)
  def load(state, context, options) do
    with {:ok, worker} <- entity(state.identifier, context) do
      {:ok, worker}
    else
      _ ->
        # TODO we need to handle ref identifiers so we can use the actual ref as our id.
        with {:ok, {agent, channel}} <- id(state.identifier),
             {:ok, agent_entity} <- Noizu.Intellect.Account.Agent.entity(agent, context),
             {:ok, channel_entity} <- Noizu.Intellect.Account.Agent.entity(agent, context),
             {:ok, account} <- ERP.ref(agent.account) do
          worker = %__MODULE__{
                     identifier: state.identifier,
                     agent: agent_entity,
                     channel: channel_entity,
                     account: account
                   } |> shallow_persist(context, options)
          {:ok, worker}
        end
    end
    |> case do
         {:ok, worker} ->
           state = %{state| status: :loaded, worker: worker}
                   |> queue_heart_beat(context, options)
           {:ok, state}
         _ -> {:error, state}
       end
  end

  #---------------------
  #
  #---------------------
  def queue_heart_beat(state, context, options \\ nil, fuse \\ 5_000) do
    # Start HeartBeat
#    identifier = {self(), :os.system_time(:millisecond)}
#    settings = apply(__pool__(), :__cast_settings__, [])
#    timeout = 15_000
#    msg = M.msg_envelope(
#      identifier: identifier,
#      type: :cast,
#      settings: M.settings(settings, spawn?: true, timeout: timeout),
#      recipient: state.identifier,
#      msg: M.s(call: :heart_beat, context: context, options: options)
#    )
#    timer = Process.send_after(self(), msg, fuse)
#    put_in(state, [Access.key(:worker), Access.key(:book_keeping, %{}), :heart_beat], timer)
    state
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
