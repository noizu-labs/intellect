defimpl Jason.Encoder, for: Tuple do
  def encode({:ref, _, _} = ref, _) do
    with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(ref) do
      sref
    end
  end
end
