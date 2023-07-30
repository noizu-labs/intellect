defmodule Noizu.Intellect.Prompt.Lingua do
  @vsn 1.0

  defstruct [
    nlp: nil,
    vsn: @vsn
  ]

  def prompt_file(%__MODULE__{nlp: :nlp_v0p5}) do
    priv_dir = :code.priv_dir(:noizu_intellect)
    {:ok, "#{priv_dir}/nlp/nlp-v0.5.md.eex"}
  end

  def minder_file(%__MODULE__{nlp: :nlp_v0p5}) do
    priv_dir = :code.priv_dir(:noizu_intellect)
    {:ok, "#{priv_dir}/nlp/nlp-v0.5.md.eex"}
  end

end

defimpl Noizu.Intellect.Prompt.DynamicContext.Protocol, for: [Noizu.Intellect.Prompt.Lingua] do
  def prompt(subject, prompt_context, context, options) do
    with {:ok, file} <- Noizu.Intellect.Prompt.Lingua.prompt_file(subject),
         {:ok, assigns} <- Noizu.Intellect.Prompt.DynamicContext.assigns(prompt_context, context, options) do
       assigns = put_in(assigns, [:section], :prompt)
       prompt = EEx.eval_file(file, [assigns: assigns])
       {:ok, prompt}
    end
  end
  def minder(subject, prompt_context, context, options) do
    with {:ok, file} <- Noizu.Intellect.Prompt.Lingua.minder_file(subject),
         {:ok, assigns} <- Noizu.Intellect.Prompt.DynamicContext.assigns(prompt_context, context, options) do
      assigns = put_in(assigns, [:section], :minder)
      minder = EEx.eval_file(file, [assigns: assigns])
      {:ok, minder}
    end
  end
end
