defmodule Noizu.Intellect.Prompts.ChatMonitor do
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
      arguments: %{current_message: current_message},
      assigns: &__MODULE__.assigns/4,
      prompt: [system:
        """
        <%= if @message_history.length > 0 do %>
        # Summary Construction
        * Summarize the content and purpose of the new message, taking into account message history for context.
        * examples: "requests a description of foo", "provides a description of foo", etc.
        * For search vectorization, describe the action (e.g., "requests a description of foo").
        * Extract features for vector DB indexing (e.g., "What is Lambda Calculus" -> ["lambda calculus", "math", ...]).

        <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.channel, assigns, @prompt_context, @context, @options) %>

        <%= Noizu.Intellect.DynamicPrompt.prompt!(@message_history, assigns, @prompt_context, @context, @options) %>

        <% else %>
        # Summary Construction
        * Summarize the content and purpose of the new message.
        * examples: "requests a description of foo", "provides a description of foo", etc.
        * For search vectorization, describe the action (e.g., "requests a description of foo").
        * Extract features for vector DB indexing (e.g., "What is Lambda Calculus" -> ["lambda calculus", "math", ...]).

        <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.channel, assigns, @prompt_context, @context, @options) %>

        <% end %>

        # New Message
        <%= Noizu.Intellect.DynamicPrompt.prompt!(@current_message, assigns, @prompt_context, @context, @options) %>

        """,
      ],
      minder: [system:
        """
        # Output Format
        Provide your final response in the following format, ensure the contents inside monitor-response are properly formatted yaml, do not convert message-analysis, chat-history, message_details etc into xml tags.

        <monitor-response>
        message_details:
          draft-summary:
            content: |-2
              [...|
              Summarize and condense the content of the original new message heavily. Trim down code examples (shorten documents, remove method bodies, etc.)
              For example:
               - original: "Zoocryptids are creatures that are rumored or believed to exist, but have not been proven by scientific evidence."
               - summary: "Definition of what zoocryptids are."
              ]
            action: |-2
              [...| Describe purpose/action of new message for vector indexing. e.g. "asks for a description of foo", "provides an explanation of foo"]
            features:
              {foreach feature extracted from message describing the content and objective of this message for future vector db indexing}
                - {feature | properly yaml formatted string}
              {/foreach}
          summary:
            content: |-2
              [...|Refine the draft-summary content further. If the draft-summary is longer than the actual message, use the original message.]
            action: |-2
              [...|Refine the draft-summary action further.]
            features:
              {foreach feature in refined feature list from draft_summary.features}
                - {feature}
              {/foreach}
        </monitor-response>
        """],
    }
  end

end
