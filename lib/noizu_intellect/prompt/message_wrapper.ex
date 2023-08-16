defmodule Noizu.Intellect.Prompt.MessageWrapper do
  @vsn 1.0
  @derive Ymlr.Encoder
  defstruct [
    type: :system,
    body: nil,
    vsn: @vsn
  ]
end
