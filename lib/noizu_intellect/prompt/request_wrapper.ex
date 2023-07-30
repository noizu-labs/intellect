defmodule Noizu.Intellect.Prompt.RequestWrapper do
  @vsn 1.0
  defstruct [
    model: "gpt-3.5-turbo-16k",
    model_settings: [],
    messages: [],
    functions: [],
    vsn: @vsn
  ]

  def messages(this, context, options) do
    messages = Enum.map(this.messages,
      fn
        (x = %Noizu.Intellect.Prompt.MessageWrapper{}) ->
        %{
          role: x.type,
          content: x.body
        }
      end)
    {:ok, messages}
  end

  def settings(this, _context, _options) do
    settings = this.model_settings
               |> put_in([:model], this.model)
               |> then(&(length(this.functions) > 0 && put_in(&1, [:functions], this.functions) || &1))
    {:ok, settings}
  end
end
