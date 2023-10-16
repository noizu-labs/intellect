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
      # INSTRUCTION PROMOPT
      PLEASE for each message output a summary of it's contents and only a summary of it's contents. PLEASE DO NOT output any comments
      before or after the summary of the message contents. PLEASE make the summary around 1/3rd of the original message size or longer if important details are lost if less.
      PLEASE REPLACE Code snippets with ellipse ("Code Here ...").

      <%= Noizu.Intellect.DynamicPrompt.prompt!(@current_message, assigns, @prompt_context, @context, @options) %>
      """
      ]
    }
  end
end
