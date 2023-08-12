defprotocol Noizu.Intellect.Prompt.DynamicContext.Protocol do
  @fallback_to_any true
  def prompt(subject, prompt_context, context, options)
  def minder(subject, prompt_context, context, options)
  def assigns(subject, prompt_context, context, options)
  def request(subject, request, context, options)
#  def flags(subject, prompt_context, context, options)
#  def features(subject, prompt_context, context, options) # {feature, :required | :conditional}
#  def services(subject, prompt_context, context, options)
#  def intuition_pumps(subject, prompt_context, context, options)
#  def enable(subject, prompt_context, context, options)
#  def disable(subject, prompt_context, context, options)
end

defimpl Noizu.Intellect.Prompt.DynamicContext.Protocol, for: Any do
  def prompt(_, _, _, _), do: nil
  def minder(_, _, _, _), do: nil
  def assigns(_, prompt_context, _, _), do: {:ok, prompt_context.assigns}
  def request(_, request, _, _), do: {:ok, request}
end
