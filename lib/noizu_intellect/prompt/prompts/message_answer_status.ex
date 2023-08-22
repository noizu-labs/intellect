defmodule Noizu.Intellect.Prompts.MessageAnswerStatus do
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
      prompt: [user:
        """
        # Instructions
        As a chat thread and content analysis engine, given the following channel, channel members, and list of chat messages,
        Analyze the conversation and identify any messages that have been answered or indicated as answered by new message.

        <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.channel, assigns, @prompt_context, @context, @options) %>

        <%= Noizu.Intellect.DynamicPrompt.prompt!(@message_history, assigns, @prompt_context, @context, @options) %>

        # Output Format
        Given the previous conversation and following new message provide the requested markdown body for the message-analysis tag.
        For each new message, continue this process of analysis, review the message, determine any previous messages new message has answered.

        ## Guidelines
        * Identify the messages that the new message is most likely responding to and discern the most suitable audience for this message.
          * For instance, a new message that elaborates on topics raised in a recent prior message is likely a response to that earlier message rather than the initiation of a new thread.

        # New Message
        <%= Noizu.Intellect.DynamicPrompt.prompt!(@current_message, assigns, @prompt_context, @context, @options) %>

        # Output Format
        Provide your final response in the following format, ensure the contents of monitor-response are properly formatted yaml.
        When template instructs to us |-2 for text use it and properly format.

        <monitor-response>
        message_analysis:
          chat-history:
            {foreach msg in Chat History message}
            - id: {msg.id}
              answered:
                - by: {message.id that has answered this message}
                  reasoning: |-2
                    [...|Provide a 1-sentence explanation for why this message has been answered | properly apply yaml formatting]
            {/foreach}
        </monitor-response>
        """,
      ],
      minder: [system: ""],
    }
  end



end
