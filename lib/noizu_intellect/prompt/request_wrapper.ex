defmodule Noizu.Intellect.Prompt.RequestWrapper do
  @vsn 1.0
  defstruct [
    model: "gpt-3.5-turbo-16k",
    model_settings: [temperature: 0.5, mak_tokens: 5000],
    prompt_context: nil,
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
               |> update_in([:retry], &(is_nil(&1) && 5 || &1))
               |> then(&(length(this.functions) > 0 && put_in(&1, [:functions], this.functions) || &1))
    {:ok, settings}
  end
end
