defmodule Noizu.Intellect.Prompt.Lingua do
  @vsn 1.0
  require EEx

  defstruct [
    nlp: nil,
    vsn: @vsn
  ]

  EEx.function_from_file(:def, :prompt__nlp_v0p5, "#{:code.priv_dir(:noizu_intellect)}/nlp/nlp-v0.5.md.eex", [:assigns], trim: true)
  EEx.function_from_file(:def, :minder__nlp_v0p5, "#{:code.priv_dir(:noizu_intellect)}/nlp/nlp-v0.5.md.eex", [:assigns], trim: true)


  def prompt(%__MODULE__{nlp: :nlp_v0p5}, assigns) do
    prompt__nlp_v0p5(assigns)
  end

  def minder(%__MODULE__{nlp: :nlp_v0p5}, assigns) do
    minder__nlp_v0p5(assigns)
  end
end

defimpl Noizu.Intellect.DynamicPrompt, for: [Noizu.Intellect.Prompt.Lingua] do
  def prompt!(subject, assigns, prompt_context, context, options) do
    with {:ok, prompt} <- prompt(subject, assigns, prompt_context, context, options) do
      prompt
    else
      _ -> ""
    end
  end
  def prompt(subject, assigns, prompt_context, _context, _options) do
    assigns = put_in(assigns, [:section], :prompt)
    {:ok, Noizu.Intellect.Prompt.Lingua.prompt(subject, assigns)}
  end
  def minder!(subject, assigns, prompt_context, context, options) do
    with {:ok, prompt} <- minder(subject, assigns, prompt_context, context, options) do
      prompt
    else
      _ -> ""
    end
  end
  def minder(subject, assigns, prompt_context, _context, _options) do
    assigns = put_in(assigns, [:section], :minder)
    {:ok, Noizu.Intellect.Prompt.Lingua.prompt(subject, assigns)}
  end
  def assigns(_, prompt_context, _,_) do
    {:ok, prompt_context.assigns}
  end
  def request(_,request,_,_) do
    {:ok, request}
  end
end
