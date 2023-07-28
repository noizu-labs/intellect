defmodule Noizu.Intellect.Redis do
  @channel_pool_size 50

  def get_channel() do
    (FastGlobal.get(:redis_channels) || build_channels())[:rand.uniform(@channel_pool_size)]
  end
  def build_channels() do
    Enum.map(1..@channel_pool_size, &({&1, :"redis_#{&1}"}))
    |> Map.new()
    |> tap(&(FastGlobal.put(:redis_channels, &1)))
  end

  def child_spec(_args) do
    v = Application.get_env(:noizu_intellect, :redis)
    uri = v[:uri] || v[:host]
    settings = Redix.URI.to_start_options(uri)
    children = Enum.map(
      1..@channel_pool_size,
      fn (index) ->
        opts = put_in(settings, [:name], :"redis_#{index}")
        Supervisor.child_spec({Redix, opts}, id: {Redix, index})
      end
    )
    build_channels()
    # Spec for the supervisor that will supervise the Redix connections.
    %{
      id: RedixSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  def command(command), do: Redix.command(get_channel(), command)
  def flush(), do: command(["FLUSHALL"])

  def get(key) do
    command(["GET", key])
  end
  def set(key, value, options \\ []) do
    command(["SET", key, value| options])
  end


  def get_binary(key) do
    case get(key) do
      {:ok, nil} -> nil
      {:ok, term} ->
        t = :erlang.binary_to_term(term)
        {:ok, t}
      _ -> nil
    end
  end

  def set_binary(key, value, options \\ []) do
    encoded = :erlang.term_to_binary(value)
    set(key, encoded, options)
  end

end
