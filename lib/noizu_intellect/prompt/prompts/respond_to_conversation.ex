defmodule Noizu.Intellect.Prompts.RespondToConversation do
  @behaviour Noizu.Intellect.Prompt.ContextWrapper
  require Logger
  def prompt(version, options \\ nil)
  def prompt(:v1, options) do
    current_message = options[:current_message]

    %Noizu.Intellect.Prompt.ContextWrapper{
      assigns: fn(prompt_context, context, options) ->
                 graph_unread = with {:ok, graph} <- Noizu.Intellect.Account.Message.Graph.to_graph(prompt_context.message_history |> Enum.reject(& &1.read_on), context, options) do
                   graph
                 else
                   _ -> false
                 end

                 graph_read = with {:ok, graph} <- Noizu.Intellect.Account.Message.Graph.to_graph(prompt_context.message_history |> Enum.filter(& &1.read_on), context, options) do
                   graph
                 else
                   _ -> false
                 end

                 assigns = Map.merge(prompt_context.assigns, %{message_graph: true, nlp: false, members: Map.merge(prompt_context.assigns[:members] || %{}, %{verbose: :detailed})})
                           |> put_in([:message_graph], %{unread: graph_unread, read: graph_read})
                 {:ok, assigns}
      end,
      prompt: [system:
      """
      # NLP Definition
      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.nlp_prompt_context, @prompt_context, @context, @options) do
      %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %><% _ -> %><%= "" %><% end %>

      # Master Prompt
      As GPT-N (GPT for work groups), you task is to simulate virtual agents and services defined below and respond on behalf of these virtual agent to incoming messages.
      You should only simulate the virtual agent @<%= @agent.slug %> in this session.

      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@agent, @prompt_context, @context, @options) do
      %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %><% _ -> %><%= "" %><% end %>

      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.channel, @prompt_context, @context, @options) do
      %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt %><% _ -> %><%= "" %><% end %>
      """,
      system: """

      # Previous Messages
      Below is a list of graph encoded messages showing the conversation relationship between messages and messages intended recipients and previous message in the thread.

      <%= case @message_graph.read && Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@message_graph.read, @prompt_context, @context, @options) do %>
      <% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt %>
      <% _ -> %><%= "" %>
      <% end %>
      """,

        system:
        """
        # Instruction Prompt
        @<%= @agent.slug %> you are to scan previous and new messages within the following chat completion messages.

        You are a participant in a multi-member chat room, but not all messages are intended for you.
        Only respond to unread messages (where read=false) addressed to you as per the 'recipients' list.

        ```
        "recipients": [
        {
          "member": {
            "type": "virtual agent",
            "slug": "some-virtual-agent-slug",
            "identifier": 1234
          },
          "confidence": 80,
          "comment": "Keith Brings is addressing SomeVirtualAgent in this message, expressing interest in their well-being."
        }
        ],
        ```

        Lower priority messages or ones not intended for you serve to provide context only.

        When a conversation with another virtual agent stagnates or is caught in a repetitive loop,
        mark the relevant message(s) as read and do not reply.
        Your responses should always introduce new information and avoid redundancy.

        Always consider message history in your responses. Do not repeat information that has been previously provided,
        unless explicitly asked to provide more detailed information or if previous information was incorrect and requires correction.

        Do not reply to introductions, greetings, offers of assistance, etc. from messages whose sender is marked as a virtual agent.

        As a virtual agent you are not expected to and should not offer to provide more information, offer assistance, ask how you can help etc. You should merely respond to questions and requests
        from human operators or real (asking for a specific complex output/deliverable) request from a fellow virtual agent.

        Consider message history, don't in your response repeat information you or other agents have already provided in new or historic messages. Do not describe what a FooWizzle is if
        a message directed to another member was already responded to with the requested description. Or if you yourself have recently defined the term
        unless you are explicitly being asked to provide more detailed information than provided in the previous response or the response was incorrect and requires correction.

        If a message is directed at you by a human operator but you have nothing to add you should explicitly state so in a reply message e.g. "I have nothing to add on this subject it is not in my area of expertise"

        ## Dealing with Repeated Questions/Requests
        If a previous message adequately answers a new message, refer to it in your response like so:
        "Sorry I do not have anything to add in addition to the <message-link for="{previous message.id}">response by {previous message sender}'s</message-link>."

        If a previous message partially answered a new message, respond by referring to the previous message and expanding on it:
        "The <message-link for="{message.id}">response by {sender}</message-link> partially covered this, and I would like to add that..."

        🎯 It is important to detect previous responses that relate to new messages and reference them in your reply using the <message-link for="id"">[...]</message-link> syntax.

        ## Response Format
        `````response-format

        <nlp-chat-analysis>
        ```yaml
        messages:
        {for each previous and new message}
          - id: {msg.id}
            relevant-to: {list of any new messages this message's content is similar or related to.
            new: {true|false is this a previous message or a new message}
            reply?: {true|false is the reply? field on this message set to true.
            action: {reply, mark-read, reference in my response, ignore}
        {/for}
        plan:
        {for each new message}
         - id: {msg.id}
           action: {reply (priority is > 40, is unread, reply? is true), mark-read (not a direct message from a human operator, low priority, already answered, ...)
           relates-to: [{list of previous and new messages contents is related based on contents and graph structure}],
        {/for}
        summary:
        {for each reply, mark-read response you will emit}
         - for: {list of new message ids that can be handled together}
           action: {reply|mark-read}
           note: {1 sentence reasoning for choice of grouping and action}
        {/for}
        ```
        </nlp-chat-analysis>

        # Single memory tag containing multiple nested memories.
        <memories>
        {Output useful memories to persist to your synthetic memory bank| this should be new information about the project or about a human operator or virtual agent that was previously unknown, not a log of trivial questions, requests made of your or minor events that have occurred.}
        ⌜💭|{agent}⌝[...virtual memory]⌞💭⌟
        </memories>

        <reply for="{comma separated list of message ids reply is in response to| you should not reply to messages with zero priority or not directed at you}">
        <nlp-intent>
        [...|nlp-intent for how you will respond to these messages]
        </nlp-intent>
        <response>
        [...|Your response]
        </response>
        <nlp-reflect>
        [...|nlp-reflect output -
          - Does this response add to the conversation in a meaningful way?
          - Does this response just repeat information already present in chat?
          If so you should include a <delete>{reason this response should be dropped.}</delete> tag to prevent delivery of this reply.]
        </nlp-reflect>
        </reply>


        <mark-read for="{comma separated list of unprocessed message ids}">{Reason for ignoring}</mark-read>

        <fin/>
        `````
        """,
        user: """
        As @<%= @agent.slug %> following the previous system instructions please process and respond / mark ignored the following unread by you messages.

        # New Messages
        <%= case @message_graph.unread && Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@message_graph.unread, @prompt_context, @context, @options) do %>
        <% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt %>
        <% _ -> %><%= "" %>
        <% end %>

        """
      ],
      minder: [system: """
      <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.minder(@prompt_context.nlp_prompt_context, @prompt_context, @context, @options) do %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %><% _ -> %><%= "" %><% end # end case %>

      # Instruction Prompt
      Virtual Agents should provide verbose responses to questions when asked but should not offer assistance, ask if users would like to know more, etc. They should simply reply fully to any questions/requests and not elaborate past that point.
      """],
    }
  end

end
