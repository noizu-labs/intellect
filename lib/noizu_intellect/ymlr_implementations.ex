defimpl Ymlr.Encoder, for: [Noizu.OpenAI.Chat, Noizu.OpenAI.Chat.Choice] do
  def encode(subject, ident_level, opts) do
    subject
    |> Map.from_struct()
    |> Ymlr.Encode.map(ident_level, opts)
  end
end
