defmodule Noizu.Intellect.Prompts.SummarizeMessage do
  @behaviour Noizu.Intellect.Prompt.ContextWrapper
  require Logger
  @impl true

  def assigns(subject, prompt_context, context, options) do
    assigns = Map.merge(
                prompt_context.assigns,
                %{
                  nlp: false,
                  members: Map.merge(prompt_context.assigns[:members] || %{}, %{verbose: :brief})
                })
              |> put_in([:current_message], subject.arguments[:current_message])
    {:ok, assigns}
  end

  def prompt(version, options \\ nil)
  def prompt(:default, options), do: prompt(:v2, options)
  def prompt(:v2, options) do
    current_message = options[:current_message]

    %Noizu.Intellect.Prompt.ContextWrapper{
      assigns: &__MODULE__.assigns/4,
      arguments: %{current_message: current_message},
      prompt: [user: """
      # Instruction Prompt
      For every user provided message output a summary of it's contents and only a summary of it's contents. Do not output any comments
      before or after the summary of the message contents. The summary should be around 1/3rd of the original message size but can be longer if important details are lost.
      Code snippets should be reduced by replacing method bodies, etc with ellipse ("Code Here ...") comments.

      """,
        user: """
        <%= for message <- @prompt_context.message_history do %>
        <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(message, @prompt_context, @context, @options) do %>
        <% {:ok, prompt} when is_bitstring(prompt)  -> %>
        <%= String.trim_trailing(prompt) %><% _ -> %><%= "" %>
        <% end  # end case %>
        <% end  # end for %>
        """
      ]
    }
  end
end
