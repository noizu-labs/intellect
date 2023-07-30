defprotocol Noizu.Intellect.Prompt.DynamicContext.Protocol do
  def prompt(subject, prompt_context, context, options)
  def minder(subject, prompt_context, context, options)
#  def flags(subject, prompt_context, context, options)
#  def features(subject, prompt_context, context, options) # {feature, :required | :conditional}
#  def services(subject, prompt_context, context, options)
#  def intuition_pumps(subject, prompt_context, context, options)
#  def enable(subject, prompt_context, context, options)
#  def disable(subject, prompt_context, context, options)
end
