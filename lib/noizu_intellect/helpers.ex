defmodule Noizu.Intellect.Helpers do

  def wait_for_condition(condition, timeout \\ 5_000, options \\ nil)
  def wait_for_condition(condition, timeout, options) do
    reference = make_ref()
    task = Task.async(fn -> wait_loop(condition, reference, options) end)
    result = Task.yield(task, timeout)
    case result do
      {:ok, response} ->
        response
      :timeout ->
        receive do
          {:condition_not_met, response} ->
            {:timeout, response}
          e ->
            {:timeout, e}
        after
          50 -> {:timeout, :timeout}
        end
    end
  end

  defp wait_loop(condition, reference, options) do
    case condition.() do
      true -> :ok
      :ok -> :ok
      {:ok, details} -> {:ok, details}
      response ->
        send(reference, {:condition_not_met, response})
        :timer.sleep(options[:poll] || 100)
        wait_loop(condition, reference, options)
    end
  end

end