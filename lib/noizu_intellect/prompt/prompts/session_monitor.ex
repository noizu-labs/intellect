defmodule Noizu.Intellect.Prompts.SessionMonitor do
  @behaviour Noizu.Intellect.Prompt.ContextWrapper
  require Logger

  def prep_assigns(subject, prompt_context, _context, _options) do
    assigns = Map.merge(
                prompt_context.assigns,
                %{
                  nlp: false,
                  members: Map.merge(prompt_context.assigns[:members] || %{}, %{verbose: :brief})
                })
              |> put_in([:current_message], subject.arguments[:current_message])
    {:ok, assigns} |> IO.inspect
  end


  @impl true
  defdelegate compile_prompt(expand_prompt, options \\ nil), to: Noizu.Intellect.Prompt.ContextWrapper

  @impl true
  defdelegate compile(this, options \\ nil), to: Noizu.Intellect.Prompt.ContextWrapper

  @impl true
  def prompt(version, options \\ nil)
  def prompt(:default, options), do: prompt(:v3, options)
  def prompt(:v3, options) do
    current_message = options[:current_message]
    %Noizu.Intellect.Prompt.ContextWrapper{
      name: __MODULE__,
      arguments: %{current_message: current_message},
      assigns: &__MODULE__.prep_assigns/4,
      prompt: [system:
        """
        <%= if @message_history.length > 0 do %>
        # SUMMARY CONSTRUCTION
        * PLEASE SUMMARIZE the content and purpose of the new message, taking into account message history for context.
        * examples: "requests a description of foo", "provides a description of foo", etc.
        * For search vectorization, PLEASE describe the action (e.g., "requests a description of foo").
        * PLEASE extract features for vector DB indexing (e.g., "What is Lambda Calculus" -> ["lambda calculus", "math", ...]).

        <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.channel, assigns, @prompt_context, @context, @options) %>

        <%= Noizu.Intellect.DynamicPrompt.prompt!(@message_history, assigns, @prompt_context, @context, @options) %>

        <% else %>
        # SUMMARY CONSTRUCTION
        * PLEASE SUMMARIZE the content and purpose of the new message.
        * examples: "requests a description of foo", "provides a description of foo", etc.
        * For search vectorization, PLEASE describe the action (e.g., "requests a description of foo").
        * PLEASE extract features for vector DB indexing (e.g., "What is Lambda Calculus" -> ["lambda calculus", "math", ...]).

        <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.channel, assigns, @prompt_context, @context, @options) %>

        <% end %>

        # NEW MESSAGE
        <%= Noizu.Intellect.DynamicPrompt.prompt!(@current_message, assigns, @prompt_context, @context, @options) %>

        """,
      ],
      minder: [user:
        """
        # OUTPUT FORMAT
        PLEASE PROVIDE YOUR FINAL RESPONSE in the following format, ensure the contents inside monitor-response are properly formatted yaml, do not convert message-analysis, chat-history, message_details etc into xml tags.
        PLEASE Do not output [...] placeholders list all items.

        <monitor-response>
        message_details:
          draft-summary:
            content: |-2
              [...|
              PLEASE SUMMARIZE AND CONDENSE the content of the original new message heavily. Trim down code examples (shorten documents, remove method bodies, etc.)
              EXAMPLE:
               - original: "Zoocryptids are creatures that are rumored or believed to exist, but have not been proven by scientific evidence."
               - summary: "Definition of what zoocryptids are."
              ]
            action: |-2
              [...| PLEASE DESCRIBE purpose/action of new message for vector indexing. e.g. "asks for a description of foo", "provides an explanation of foo"]
            features:
              {FOREACH feature extracted from message describing the content and objective of this message for future vector db indexing}
                - {feature | properly yaml formatted string}
              {/FOREACH}
          summary:
            content: |-2
              [...| PLEASE Refine the draft-summary content further. If the draft-summary is longer than the actual message, use the original message.]
            action: |-2
              [...| PLEASE Refine the draft-summary action further.]
            features:
              {FOREACH feature in refined feature list from draft_summary.features}
                - {feature}
              {/FOREACH}
        </monitor-response>
        """],
    }
  end
  def prompt(:v2, options) do
    current_message = options[:current_message]
    %Noizu.Intellect.Prompt.ContextWrapper{
      name: __MODULE__,
      arguments: %{current_message: current_message},
      assigns: &__MODULE__.prep_assigns/4,
      prompt: [user:
        """
        <%= if @message_history.length > 0 do %>
        # Instructions
        As a chat thread and content analysis engine and content summarizer, your task is to analyze the given channel, channel members, and list of chat messages. Follow these guidelines:

        ## Analyze the Conversation
        - Identify relationships between messages, including "relates-to" connections and target audience.
        - Determine what previous and new messages relate to, considering responses, continuations, follow-ups, restatements, duplicates, or covering the same topic.

        ## Handling Specific Scenarios
        - A message relates to a previous message if it clearly responds to or continues the topic of that message, or repeats that message.
        - Ensure accurate identification of the sender or previous and new messages, avoiding confusion between them.
        - Carefully match questions and answers, using content and context clues.
        ```pseudo-elixir
          message_relates(msg, other_msg) do
            cond do
            other_msg is response to msg -> true
            msg repeats other_msg request -> true
            subject of msg is the same as other_msg -> true
            msg is response to other_msg -> true
            msg is in response to a another_msg (or chain) in response to other_msg -> true
            other_msg is in response to a another_msg (or chain) in response to msg -> true
            [...]
            :else -> false
            end
          end
        ```

        ## Considerations for Different Members
        - Consider members' backgrounds, personality types, and response preferences when determining the likely audience and responses.

        ## Examples
        - If a message asks "What is a monad?" and the following message explains monads, the second message relates to the first.
        - A message from the sender should not be marked as "replies to @{agent}" if the sender is the agent.

        ## Review
        - Ensure consistent application of these guidelines throughout the analysis.
        - Correct any discrepancies by linking new messages to appropriate responding_to IDs.
        - Examine feature flags and tags in new messages and include them in the analysis.

        Bear in mind the different confidence levels based on how members are addressed or mentioned in the message, and continue this process of analysis for each new message.

        <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.channel, assigns, @prompt_context, @context, @options) %>

        <%= Noizu.Intellect.DynamicPrompt.prompt!(@message_history, assigns, @prompt_context, @context, @options) %>

        # Output Format
        Given the previous conversation and following new message provide the requested markdown body for the message-analysis tag.

        <% else %>

        # Instructions

        ## Review
        As a chat thread and content analysis engine and content summarizer, given the following channel, and channel members
        determine the most likely audience for new messages based on their background, message contents and direct channel member mentions.
        Provide the requested markdown body for the message-analysis tag.

        <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.channel, assigns, @prompt_context, @context, @options) %>

        <% end %>


        ## New Message Analysis

        ### Relationship Identification
        * Identify the messages that the new message is most likely responding to.
        * Consider elaborations, continuations, and recent prior messages.
        * Correct discrepancies by linking new messages to appropriate responding_to IDs.
        * 🎯 When identifying relationships between messages:
          - Ensure that a message from the sender is never marked as "replies to @{agent}" if the sender is the agent.
          - Carefully analyze the content and context to match responses to specific questions, especially when a response is a description or explanation. Utilize keywords and contextual clues to make accurate connections.

        ### Feature and Tag Examination
        * Examine the new message for feature flags and tags.
        * Include extracted features in the 'feature tags' part of the summary response.

        ### Summary Construction
        * Summarize the content and purpose of the new message.
          * examples: "requests a description of foo", "provides a description of foo", etc.
        * For search vectorization, describe the action (e.g., "requests a description of foo").
        * Extract features for future vector DB indexing (e.g., "What is Lambda Calculus" -> ["lambda calculus", "math", ...]).

        # Instruction for New Message
        For each new message, below continue this process of analysis, review the message, determine potential recipients based on message content and context and determine the message sender type from the message.sender field.

        ## Confidence Levels for Message Audience
        Use this below logic to help determining audience and audience confidence for each new message in the following # New Message section. Apply the first matching confidence level/highest matching confidence level.
        It is a guide but not an absolute.

        <%= if true do %>
        ```pseudo-elixir
        def function determine_confidence_level(member, msg) do
          h = (msg.senderType == "human operator")
          c = cond do
            msg.contents =~ member.slug/i -> h && 90 || 60
            condition(msg.contents, mentions member by name) -> h && 80 || 50
            msg.contents =~ "@everyone"/i || msg.contents =~ "@channel"/i -> h && 70 || 40
            condition(msg.contents, mentions member by name) -> 50
            h && condition(msg.contents, relates to domain expertise of member) && condition(msg.contents, does not reference any members directly) -> 20
            :else -> 0
          end
          min(100, c + (h && condition(msg.contents, relates to domain expertise of member) && 15 || 0))
        end
        ```
        <% end %>

        Note:
        - sender type refers to the sender of the new message not the member type of the channel member.
        - A member is mentioned by slug if referenced like @{member.slug | case insensitive} in message.contents, if referenced by name without the `@` in message contents then they were mentioned by name not by slug.
        - A message is in a member's domain if it's subject relates to the role/duty/interests of member in their channel member definition entry for example if the message is asking an elixir question and the channel member is
        an elixir developer then the message is in their domain.

        <%= if false do %>
        | sender type       | member mentioned by slug | member mentioned by name | indirect mention | message in member domain and no direct mentions | then confidence level | reason |
        |-------------------|--------------------------|--------------------------|------------------|--------------------------|-----------------------|--------|
        | human operator    | t                        | *                        | f                | *                        | 90                    | Direct mention by Human Operator |
        | human operator    | *                        | t                        | f                | *                        | 80                    | Name mention by Human Operator   |
        | human operator    | t                        | *                        | t                | *                        | 70                    | Indirect mention by Human Operator |
        | human operator    | *                        | t                        | t                | *                        | 60                    | Name indirect mention by Human Operator |
        | human operator    | *                        | *                        | *                | t                        | 50                    | Message pertains to agent domain |
        | virtual person     | t                        | *                        | f                | *                        | 50                    | Direct mention by virtual person |
        | virtual person     | *                        | t                        | f                | *                        | 50                    | Name mention by virtual person   |
        | virtual person     | t                        | *                        | t                | *                        | 40                    | Indirect mention by virtual person |
        | virtual person     | *                        | t                        | t                | *                        | 30                    | Name indirect mention by virtual person |
        | virtual person     | *                        | *                        | *                | t                        | 20                    | Message pertains to agent domain |
        | *                 | *                        | *                        | *                | *                        | 0                     | Not relevant to agent. |
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
        message_analysis:
          chat-history:
            {foreach previous_msg in Chat History message}
            - id: {previous_msg.id}
              relates-to: {list of previous messages previous_msg relates to}
              relates-to-reasoning: |-2
                [...|Provide 1 sentence explaining why this message relates to any previous messages e.g. "This message is a duplicate of the previous message"]
              relevant: {true|false - is previous message relevant to new based on its content and the new message's content.}
              reasoning: |-2
                [...|Provide a 1-sentence explanation for why this message relates or doesnt relate to new message]
            {/foreach}
          new-message:
            sender: {sender slug}
            sender-type: {sender type of new_message}
            audience:
              {foreach channel member}
                - member-slug: @{member.slug}
                  referenced-by-slug? : {true|false - in contents of new message}
                  referenced-by-name? : {true|false - in contents of new message}
                  content-in-member-domain? : {true|false - in contents of new message}
                  indirect-reference? : {true|false - in contents of new message}
                  confidence: {determine_confidence_level(member, new_message)}
              {/foreach}

        message_details:
          for: {id of the new message}
          sender: {sender slug}
          sender-type: {sender type of new message}

          relates-to:
            {foreach message new message relates to with confidence > 30}
              - for: {previous_msg.id}
                confidence: {confidence interval 0-100}
                explanation: [...|Provide a 1-sentence blurb explaining why the new message is relevant to this prior message]
            {/foreach}

          audience:
            {foreach probable recipient of the new message | exclude if confidence < 30}
              - for: {integer id of channel member}
                confidence: {determine_confidence_level(member, new_message)}
                explanation: |-2
                  [...|Provide a 1-sentence blurb explaining why the new message is relevant to the member]
            {/foreach}

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
