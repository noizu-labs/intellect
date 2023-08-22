defmodule Noizu.Intellect.Prompts.SummarizeMessage do
  @behaviour Noizu.Intellect.Prompt.ContextWrapper
  require Logger

  def assigns(subject, prompt_context, _context, _options) do
    assigns = Map.merge(
                prompt_context.assigns,
                %{
                  nlp: false,
                  members: Map.merge(prompt_context.assigns[:members] || %{}, %{verbose: :brief})
                })
              |> put_in([:current_message], subject.arguments[:current_message])
    {:ok, assigns}
  end

  @impl true
  defdelegate compile_prompt(expand_prompt, options \\ nil), to: Noizu.Intellect.Prompt.ContextWrapper

  @impl true
  defdelegate compile(this, options \\ nil), to: Noizu.Intellect.Prompt.ContextWrapper

  @impl true
  def prompt(version, options \\ nil)
  def prompt(:default, options), do: prompt(:v2, options)
  def prompt(:v2, options) do
    current_message = options[:current_message]

    %Noizu.Intellect.Prompt.ContextWrapper{
      name: __MODULE__,
      assigns: &__MODULE__.assigns/4,
      arguments: %{current_message: current_message},
      prompt: [user: """
      # Instruction Prompt
      For every user provided message output a summary of it's contents and only a summary of it's contents. Do not output any comments
      before or after the summary of the message contents. The summary should be around 1/3rd of the original message size but can be longer if important details are lost.
      Code snippets should be reduced by replacing method bodies, etc with ellipse ("Code Here ...") comments.

      <%= Noizu.Intellect.DynamicPrompt.prompt!(@current_message, assigns, @prompt_context, @context, @options) %>
      """
      ]
    }
  end
end
