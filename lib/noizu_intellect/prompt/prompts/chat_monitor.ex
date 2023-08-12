defmodule Noizu.Intellect.Prompts.ChatMonitor do
  @behaviour Noizu.Intellect.Prompt.ContextWrapper
  require Logger
  @impl true

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

  def prompt(version, options \\ nil)
  def prompt(:default, options), do: prompt(:v2, options)
  def prompt(:v2, options) do
    current_message = options[:current_message]
    %Noizu.Intellect.Prompt.ContextWrapper{
      arguments: %{current_message: current_message},
      assigns: &__MODULE__.assigns/4,
      prompt: [user:
        """
        <%= if @message_history.length > 0 do %>
        # Instructions
        As a chat thread and content analysis engine and content summarizer, given the following channel, channel members, and list of chat messages,
        Analyze the conversation and identify the relationships between messages, including relates-to and target audience connections, and messages previous and new messages relate to.

        A message relates to a previous message if it is a response to, continuation of, follow up to, restatement of, duplicate of, or covers the same topic as the previous message.

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

        <% else %>

        # Instructions

        ## Review
        As a chat thread and content analysis engine and content summarizer, given the following channel, and channel members
        determine the most likely audience for new messages based on their background, message contents and direct channel member mentions.
        Provide the requested markdown body for the message-analysis tag.

        <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.channel, @prompt_context, @context, @options) do %>
        <% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %>
        <% _ -> %><%= "" %>
        <% end %>
        <% end %>

        ### Note
        - Messages that include @[member.slug| case insensitive] should list that user as a high confidence (90) recipient.
        - Messages including @everyone (case insensitive) or @channel (case insensitive) should list all members as med-high confidence (70) recipients.
        - Messages that mention (without a slug) someone by name in passing without directly querying them should have a med-low confidence level (50)
        - Messages addressed to someone by name should have a high-med-high confidence (80) if sent by a human operator or (50) if sent by a virtual agent.

        # New Message
        For each new message, continue this process of analysis, review the message, determine potential recipients based on message content and context.
        Bear in mind the different confidence levels that should be applied based on the manner in which members are addressed or mentioned in the message.

        ## Guidelines
        * Identify the messages that the new message is most likely responding to and discern the most suitable audience for this message.
          * For instance, a new message that elaborates on topics raised in a recent prior message is likely a response to that earlier message rather than the initiation of a new thread.
        * While the existing conversation should guide this analysis, bear in mind it may contain errors. If you identify such discrepancies, correct them by linking new messages to the appropriate responding_to IDs.
        * Examine the new message for feature flags and tags. These should be extracted and included in the 'feature tags' part of your summary response.
        * Construct a succinct summary of the new message's content to be incorporated into the 'summary' section of your response.
        * Construct a succient description of the purpose of the new message for search vectorization e.g. "requests a description of foo", "provides a description of foo", etc.
        * Extract features from new message describing the content and objective of this message for future vector db indexing.
          For example "What is Lambda Calculus" -> ["lambda calculus", "math", "functional programming", "describe"]

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
              relates-to: {list of previous messages this message relates to}
              relates-to-reasoning: {Provide 1 sentence explaining why this message relates to any previous messages e.g. "This message is a duplicate of the previous message"}
              relevant: {true|false - is previous message relevant to new based on its content and the new message's content.}
              reasoning: {Provide a 1-sentence explanation for why this message relates or doesnt relate to new message}
            {/foreach}
        message_details:
          for: {id of the new message}
          relates-to:
          {foreach message new message relates to with confidence > 30}
            - for: {previous_msg.id}
              confidence: {confidence interval 0-100}
              explanation: [...|Provide a 1-sentence blurb explaining why the new message is relevant to this prior message]
          {/foreach}
          audience:
            {foreach probable recipient of the new message | exclude if confidence < 30}
              - for: {integer id of channel member}
                confidence: {0-100}
                explanation: [...|Provide a 1-sentence blurb explaining why the new message is relevant to the member]
            {/foreach}
          draft-summary:
            content: |-2
              [...|
              Summarize and condense the content of the original new message heavily. Trim down code examples (shorten documents, remove method bodies, etc.)
              For example:
              original: "Zoocryptids are creatures that are rumored or believed to exist, but have not been proven by scientific evidence."
              summary: "Definition of what zoocryptids are."
              ]
            action: |-2
              [...| Describe purpose/action of new message for vector indexing. e.g. "asks for a description of foo", "provides an explanation of foo"]
            features:
              {foreach feature extracted from message describing the content and objective of this message for future vector db indexing}
                - {feature}
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
        """,
      ],
      minder: [system: ""],
    }
  end
  def prompt(:v1, options) do
    current_message = options[:current_message]

    %Noizu.Intellect.Prompt.ContextWrapper{
      assigns: fn(prompt_context, context, options) ->
                 graph = with {:ok, graph} <- Noizu.Intellect.Account.Message.Graph.to_graph(prompt_context.message_history, prompt_context.channel_members, context, options) do
                   graph
                 else
                   _ -> false
                 end

                 assigns = Map.merge(prompt_context.assigns, %{message_graph: true, nlp: false, members: Map.merge(prompt_context.assigns[:members] || %{}, %{verbose: :brief})})
                           |> put_in([:message_graph], graph)
                           |> put_in([:current_message], current_message)
                 {:ok, assigns}
      end,
      prompt: [user:
        """
        <%= if @message_graph do %>
         # Instructions
        As a chat thread and content analysis engine and content summarizer, given the following channel, channel members, and graph-encoded chat conversation,
        Analyze the conversation graph and identify the relationships between messages, including reply-to and target audience connections.

        # Complete Messages
        A complete message is one that has been answered or addressed by a subsequent message. This typically happens when a question has been asked, and a later message provides the answer, thereby 'completing' the initial question. Similarly, a request or a call to action is 'complete' once it has been fulfilled or responded to by a subsequent message.

        # Indications of Completion
        Completion can often be inferred through context, relevance, and the content of subsequent messages. For example:
        - If a message asks "What is a rainbow?", a later message that describes what a rainbow is would complete the initial message.
        - If a message requests certain data and a subsequent message provides this data, the initial message is complete.

        # Completion in this Analysis
        As you analyze the conversation, determine whether each new message completes any of the previous messages. This completion check is a crucial part of understanding conversation flows and identifying information exchanges.
        Note that completion does not mean the conversation on a topic has to end; instead, it's an indication that a particular query, request, or call to action has been addressed.

        <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.channel, @prompt_context, @context, @options) do %>
        <% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt %>
        <% _ -> %><%= "" %>
        <% end %>

        # Conversation Graph
        <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@message_graph, @prompt_context, @context, @options) do %>
        <% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt %>
        <% _ -> %><%= "" %>
        <% end %>

        # Output Format
        In your output, mark any completed messages with 'complete?: true' and provide a brief reasoning for this determination. Remember, a message is 'complete' when it has been answered or addressed by a subsequent message in the conversation.

        <% else %>

        # Instructions

        ## Review
        As a chat thread and content analysis engine and content summarizer, given the following channel, and channel members
        determine the most likely audience for new messages based on their background, message contents and direct channel member mentions.
        Provide the requested markdown body for the message-analysis tag.

        <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.channel, @prompt_context, @context, @options) do %>
        <% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %>
        <% _ -> %><%= "" %>
        <% end %>
        <% end %>

        ### Note
        - Messages that include @[member.slug| case insensitive] should list that user as a high confidence (90) recipient.
        - Messages including @everyone (case insensitive) or @channel (case insensitive) should list all members as med-high confidence (70) recipients.
        - Messages that mention (without a slug) someone by name in passing without directly querying them should have a med-low confidence level (50)
        - Messages addressed to someone by name should have a high-med-high confidence (80) if sent by a human operator or (50) if sent by a virtual agent.

        # New Message
        For each new message, continue this process of analysis. Review the message, determine potential recipients based on message content, and set confidence levels accordingly. Always remember to consider prior messages in the context when evaluating if the new message completes an earlier one.
        Also, bear in mind the different confidence levels that should be applied based on the manner in which members are addressed or mentioned in the message.

        ## Guidelines
        * Identify the messages that the new message is most likely responding to and discern the most suitable audience for this message.
          * For instance, a new message that elaborates on topics raised in a recent prior message is likely a response to that earlier message rather than the initiation of a new thread.
        * While the existing chat graph structure should guide this analysis, bear in mind it may contain errors. If you identify such discrepancies, correct them by linking new messages to the appropriate responding_to IDs.
        * Examine the message for feature flags and tags. These should be extracted and included in the 'feature tags' part of your summary response.
        * Evaluate if the new message serves as an answer to a previous one. If it does, mark the 'complete' flag as true under 'replying-to'.
          * As an example, if a message explains what a specific term or concept is in response to a question like "what is this term/concept?", the message providing the explanation should mark the inquisitive message as complete.
        * Consider what the preceding message was seeking. If the new message fulfills the request for information or resources made by the prior message, then it has served to complete the earlier message.
        * Construct a succinct summary of the new message's content to be incorporated into the 'summary' section of your response.
        * Extract features from new message describing the content and objective of this message for future vector db indexing.
          For example "What is Lambda Calculus" -> ["lambda calculus", "math", "functional programming", "describe"]

        <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@current_message, @prompt_context, @context, @options) do %>
        <% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %>
        <% _ -> %><%= "" %>
        <% end %>

        # Output Format
        Provide your final response in the following format, insure the contents of monitor-response are properly formatted yaml.

        <%= if true do %>
        <monitor-response>
          message_analysis:
           - messages:
           {foreach previous message| take into account if a previous message poses a question that a new message provides an answer to, it is marked as relevant and complete. Similarly, if a previous message discusses the same subject based on its content, it is also marked as relevant.}
             - id: {msg.id}
               relevant: {true|false - based on the new message's relation or relevance to this message.}
               complete: {true|false - based on whether the new message responds to this message or indicates it has been answered.}
               reasoning: {Provide a 1-sentence explanation}
            {/foreach}
          message_details:
            for: {id of the new message}
            replying_to:
              {foreach message new message likely is a response or continuation to | exclude messages with confidence < 30}
              - for: {previous_msg.id}
                confidence: {confidence interval 0-100}
                complete: {true|false - based on whether the new message answers the previous message's query or indicates it has been answered. If the new message provides an explanation that responds to a question asked by a previous message, the previous message is deemed complete.}
                completed_by: {new_msg.id or the msg.id of the previous message that the new message indirectly indicates has answered this message}
                explanation: [...|Provide a 1-sentence blurb explaining why the new message is relevant to the previous message]
              {/foreach}
          audience:
            {foreach probable recipient of the new message | exclude if confidence < 30}
            - for: {(integer) member.identifier}
              confidence: {0-100}
              explanation: [...|Provide a 1-sentence blurb explaining why the new message is relevant to the member]
            {/foreach}
          draft_summary:
            content: |-2
              [...|
                Summarize and condense the content of the original new message heavily. Trim down code examples (shorten documents, remove method bodies, etc.)
                For example:
                original: "Zoocryptids are creatures that are rumored or believed to exist, but have not been proven by scientific evidence."
                summary: "Definition of what zoocryptids are."
              ]
            features:
              {foreach feature extracted from message describing the content and objective of this message for future vector db indexing}
              - {feature}
              {/foreach}
          summary:
            content: |-2
              [...|Refine the draft-summary further. If the draft-summary is longer than the actual message, simply use the original message.]
            features:
              {foreach feature in refined feature list from draft_summary.features}
              - {feature}
              {/foreach}
        </monitor-response>
        <% else %>
        <message-analysis>
        <!-- Analysis Section -->
        ```markdown
        messages:
        {foreach previous message| take into account if a previous message poses a question that a new message provides an answer to, it is marked as relevant and complete. Similarly, if a previous message discusses the same subject based on its content, it is also marked as relevant.}
        - id: {msg.id}
        relevant?: {true|false - based on the new message's relation or relevance to this message.}
        complete?: {true|false - based on whether the new message responds to this message or indicates it has been answered.}
        reasoning: {Provide a 1-sentence explanation}
        {/foreach}
        ```
        </message-analysis>

        <message-details for="{id of the new message}">
        <replying-to>
        {foreach message new message likely is a response or continuation to | exclude messages with confidence < 30}
        <message
            for="{previous_msg.id}"
            confidence="confidence interval 0-100"
            complete="{true|false - based on whether the new message answers the previous message's query or indicates it has been answered. If the new message provides an explanation that responds to a question asked by a previous message, the previous message is deemed complete.}"
            completed_by="{new_msg.id or the msg.id of the previous message that the new message indirectly indicates has answered this message}"
        >[...|Provide a 1-sentence blurb explaining why the new message is relevant to the previous message]</message>
        {/foreach}
        </replying-to>
        <audience>
        {foreach probable recipient of the new message | exclude if confidence < 30}
        <member
            for="(integer) member.identifier"
            confidence="0-100">[...|Provide a 1-sentence blurb explaining why the new message is relevant to the member]</member>
        {/foreach}
        </audience>

        <draft-summary>
        [...|Summarize and condense the content of the original new message heavily. Trim down code examples (shorten documents, remove method bodies, etc.)
        For example:
        original: "Zoocryptids are creatures that are rumored or believed to exist, but have not been proven by scientific evidence."
        summary: "Definition of what zoocryptids are."
        ]
        <features>
            [...| extract tags/feature strings describing the content and objective of this message for future vector db indexing
            <feature>{Tag/Feature correlating to message for use in future VDB search/lookup}</feature>
            ]
        </features>
        </draft-summary>
        <summary>
        [...|Refine the draft-summary further. If the draft-summary is longer than the actual message, simply use the original message.]
        <features>
            [...| Refine features from the draft-summary further.
            <feature>{Tag/Feature}</feature>
            ]
        </features>
        </summary>
        </message-details>
        <% end %>
        """,
      ],
      minder: [system: ""],
    }
  end



end
