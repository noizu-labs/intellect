defprotocol Noizu.Intellect.DynamicPrompt do
  @fallback_to_any true
  def prompt!(subject, assigns, prompt_context, context, options)
  def prompt(subject, assigns, prompt_context, context, options)
  def minder!(subject, assigns, prompt_context, context, option)
  def minder(subject, assigns, prompt_context, context, options)
  def assigns(subject, prompt_context, context, options)
  def request(subject, request, context, options)
#  def flags(subject, prompt_context, context, options)
#  def features(subject, prompt_context, context, options) # {feature, :required | :conditional}
#  def services(subject, prompt_context, context, options)
#  def intuition_pumps(subject, prompt_context, context, options)
#  def enable(subject, prompt_context, context, options)
#  def disable(subject, prompt_context, context, options)
end

defimpl Noizu.Intellect.DynamicPrompt, for: Any do
  def prompt!(_, _, _, _, _), do: nil
  def prompt(_, _, _, _, _), do: nil
  def minder!(_, _, _, _,_), do: nil
  def minder(_, _, _, _, _), do: nil
  def assigns(_, prompt_context, _, _), do: {:ok, prompt_context.assigns}
  def request(_, request, _, _), do: {:ok, request}
end
