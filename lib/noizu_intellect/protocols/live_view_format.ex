defprotocol Noizu.Intellect.LiveView.Encoder do
  @fallback_to_any true
  def encode!(subject, context, options \\ nil)
end

defimpl Noizu.Intellect.LiveView.Encoder, for: [Any] do

  def encode!(subject, context, options \\ nil)
  def encode!(subject, context, options) when is_list(subject), do: Enum.map(subject, & Noizu.Intellect.LiveView.Encoder.encode!(&1, context, options))
  def encode!(subject,_,_), do: subject
end
