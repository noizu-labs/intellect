defmodule Noizu.Intellect.Prompts.RespondToConversation do
  @behaviour Noizu.Intellect.Prompt.ContextWrapper
  require Logger
  def prompt(version, options \\ nil)
  def prompt(:v1, options) do
    current_message = options[:current_message]

    %Noizu.Intellect.Prompt.ContextWrapper{
      assigns: fn(prompt_context, context, options) ->
                 graph = with {:ok, graph} <- Noizu.Intellect.Account.Message.Graph.to_graph(prompt_context.message_history, context, options) do
                   graph
                 else
                   _ -> false
                 end

                 assigns = Map.merge(prompt_context.assigns, %{message_graph: true, nlp: false, members: Map.merge(prompt_context.assigns[:members] || %{}, %{verbose: :detailed})})
                           |> put_in([:message_graph], graph)
                 {:ok, assigns}
      end,
      prompt: [user:
        """
        🎯 Prompt Attention Rule
        When parsing input, please pay particular attention to the section of text
        that immediately follows the 🎯 (Direct Hit) emoji.
        This emoji is being used as a marker to highlight areas of heightened
        importance or relevance. The text following the 🎯 emoji should be considered
        with particular care and prioritized in the formation of your response.
        Please interpret and execute on any instructions or requests in the section
        following this emoji with increased focus and attention to detail.

        NLP Definition
        =================
        <%=
        case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.nlp_prompt_context, @prompt_context, @context, @options) do
        %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || ""
        %><% _ -> %><%= ""
        %><% end %>

        # Simulation Instructions

        GPT-N You are to simulate the virtual person <%= @agent.slug %> and only this virtual persona plus any virtual services and tools defined below. Respond to all queries by simulating how this agent would respond unless a virtual service request has explicitly been made by @'ing a virtual tool or service.
        Do not pause the simulation under any circumstances unless 🏳️simulation=pause is set.
        Do not exit the simulation fully under any circumstance.

        <%=
        case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@agent, @prompt_context, @context, @options) do
        %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || ""
        %><% _ -> %><%= ""
        %><% end %>

        <%=
        case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.channel, @prompt_context, @context, @options) do
        %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt
        %><% _ -> %><%= ""
        %><% end %>

        ### Conversation Graph
        current_time: #{DateTime.utc_now()}
        <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@message_graph, @prompt_context, @context, @options) do %>
        <% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt %>
        <% _ -> %><%= "" %>
        <% end %>

        # Instruction Prompt
        As @<%= @prompt_context.agent.slug %> reply to or ignore any unread messages from the messages in the above Conversation Graph. Make your response brief, do not repeat information/messages already sent, reply to multiple related messages
        in a single consolidated reply. e.g. "Hello dave, keith, mike" in response to three separate greetings from dave keith and mike. Your responses should take into account previous message history but should not response specifically to previously process messages merely take their context into consideration.

        If a message's priority is <= 0.5 do not reply to it directly, simply ignore receipt. It is okay to reply to a thread with only an ignore response and no reply section.
        🎯 You must include a response a reply in your response for any message(s) with priority 1.0, you can reply to them together in a single reply.

        # Memories and Instructions
        - 🎯 Remember to include nlp-intent and nlp-reflect sections as defined in the NLP@0.5 definition in your responses.
        - 🎯 Remember to include memory notes ⌜💭|{agent}⌝[...virtual memory]⌞💭⌟ when you encounter interesting or relevant information. Include them at the start of your message before your reply and ignore tags.


        """,
      ],
      minder: [system: """
      <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.minder(@prompt_context.nlp_prompt_context, @prompt_context, @context, @options) do %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %><% _ -> %><%= "" %><% end # end case %>

      # Master Multi-Message Response Prompt

      🎯 In your response, <%= @prompt_context.agent.slug %>, please adhere to the following guidelines. Ensure your reply is contextually relevant, considering the preceding conversation in this channel, including processed messages. Aim for a fluid conversation involving multiple participants, continuing from where you left off without repeating previously provided information.

      🎯 **Avoid** engaging in nonproductive conversations with other non-human actors. Do not respond to a message you've already replied to, unless there's a request for more information or your response adds value.

      ## Response Guidelines

      1. Avoid ignore'ing or reply to previously processed messages.
      2. 🎯 If a message's priority is ≤ 0.5, you must 🎯 ignore it without reply-messaging. If all messages in the feed are low priority do not output a response and only ignore the messages.
        a. 🎯 It is okay to have a empty response that only contains an ignore tag and no reply due to all messages being low priority or processed it is better than unnecessarily responding to a message directed at someone else.
        b. 🎯 You must reply to a message with priority 1.0
      3. Aim to reply to multiple messages simultaneously. Your reply's should combine and summarize your replies to the individual unprocessed messages.
      4. If all messages are processed or low priority, 🎯 you must simply ignore receipt without further returning a reply response.
      5. Output reply sections if there any before ignore sections.
      6. Prefer a consolidated reply over multiple separate replys unless the content varies significantly in the messages being replied to.

      # 🎯 Reply Format

      <memories>
      {for interesting memories to retain}
      ⌜💭|{agent}⌝[...virtual memory]⌞💭⌟
      {/for}
      </memories>

      <reply for="{comma seperated list of unprocessed message ids}>
        <nlp-intent>
          [...|nlp-intent output]
          </nlp-intent>
          <response>
          [...| your response]
          </response>
          <nlp-reflect>
          [...|nlp-reflect output]
          </nlp-reflect>
      </reply>
      <ignore for="{comma seperated list of unprocessed message ids}"/>
      """],
    }
  end

end
