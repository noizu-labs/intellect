defmodule Noizu.Intellect.Service.Agent.Worker do
  require Noizu.Service.Types
  use Noizu.Entities
  import Ecto.Query

  @vsn 1.0
  @sref "worker-agent"
  @persistence redis_store(Noizu.Intellect.Service.Agent.Worker, Noizu.Intellect.Repo)
  def_entity do
    identifier :integer
    field :book_keeping, %{}
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end
  use Noizu.Service.Worker.Behaviour

  #-------------------
  #
  #-------------------
  def init(R.ref(module: __MODULE__, identifier: identifier), _args, _context) do
    %__MODULE__{
      identifier: identifier
    }
  end

  #-------------------
  #
  #-------------------
  def load(state, context), do: load(state, context, nil)
  def load(state, context, options) do
    _current_time = options[:_current_time] || DateTime.utc_now()
    worker = %__MODULE__{
      identifier: state.identifier
    }
    state = %{state| status: :loaded, worker: worker}
            |> queue_heart_beat(context, options)
    {:ok, state}
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

  defmodule Repo do
    use Noizu.Repo
    def_repo()
  end
end
