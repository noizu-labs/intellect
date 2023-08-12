defmodule Noizu.Intellect.Prompts.MessageAnswerStatus do
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
      prompt: [user:
        """
        # Instructions
        As a chat thread and content analysis engine, given the following channel, channel members, and list of chat messages,
        Analyze the conversation and identify any messages that have been answered or indicated as answered by new message.

        <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.channel, @prompt_context, @context, @options) do %>
        <% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt %>
        <% _ -> %><%= "" %>
        <% end %>

        <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@message_history, @prompt_context, @context, @options) do %>
        <% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt %>
        <% _ -> %><%= "" %>
        <% end %>

        # Output Format
        Given the previous conversation and following new message provide the requested markdown body for the message-analysis tag.

        # New Message
        For each new message, continue this process of analysis, review the message, determine any previous messages new message has answered.

        ## Guidelines
        * Identify the messages that the new message is most likely responding to and discern the most suitable audience for this message.
          * For instance, a new message that elaborates on topics raised in a recent prior message is likely a response to that earlier message rather than the initiation of a new thread.

        <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@current_message, @prompt_context, @context, @options) do %>
        <% {:ok, prompt} when is_bitstring(prompt) -> %>
        <%= prompt || "" %>
        <% _ -> %><%= "" %>
        <% end %>

        # Output Format
        Provide your final response in the following format, ensure the contents of monitor-response are properly formatted yaml.

        <monitor-response>
        message_analysis:
          chat-history:
            {foreach Chat History message}
            - id: {previous_msg.id}
              answered:
                - by: {message id that has answered this message}
                  reasoning: {Provide a 1-sentence explanation for why this message has been answered}
            {/foreach}
        </monitor-response>
        """,
      ],
      minder: [system: ""],
    }
  end



end
