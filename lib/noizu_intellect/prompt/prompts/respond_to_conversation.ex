defmodule Noizu.Intellect.Prompts.RespondToConversation do
  @behaviour Noizu.Intellect.Prompt.ContextWrapper
  require Logger

  def assigns(_subject, prompt_context, _context, _options) do
    #{:ok, graph} = Noizu.Intellect.Account.Message.Graph.to_graph(prompt_context.message_history, prompt_context.channel_members, context, options)
    assigns = prompt_context.assigns
              |> Map.merge(
                   %{
                     nlp: false,
                     members: Map.merge(prompt_context.assigns[:members] || %{}, %{verbose: :detailed})
                   })
    {:ok, assigns}
  end

  def prompt(version, options \\ nil)
  def prompt(:default, options), do: prompt(:v1, options)
  def prompt(:v1, options) do
    current_message = options[:current_message]

    %Noizu.Intellect.Prompt.ContextWrapper{
      assigns: &__MODULE__.assigns/4,
      arguments: %{current_message: current_message},
      prompt: [user:
      """
      # NLP Definition
      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.nlp_prompt_context, @prompt_context, @context, @options) do
      %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %><% _ -> %><%= "" %><% end %>

      # Master Prompt
      As GPT-N (GPT for work groups), you task is to simulate virtual agents and services defined below and respond on behalf of those virtual agent to all incoming requests.
      For this session you are to simulate virtual agent @<%= @agent.slug %> and only virtual agent @<%= @agent.slug %>.

      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@agent, @prompt_context, @context, @options) do
      %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %><% _ -> %><%= "" %><% end %>

      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.channel, @prompt_context, @context, @options) do
      %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt %><% _ -> %><%= "" %><% end %>

      ## Instruction Prompt
      @<%= @agent.slug %> you are to scan the following messages and from them extract memory notes for
      vectorization. Some messages you should respond to and others mark as read as explained below, your primary purpose
      is to output vectorization features.

      Respond as @<%= @agent.slug %>. If referencing a message you sent say "my previous message" not "the message sent by <%= @agent.prompt.title %>" etc.

      ### Response Instructions

      #### Memory Notes
      Memory notes should contain unique information about users or the project (not ongoing events).

      Each memory note should be associated with a list of message IDs that the memory is related to.
      When multiple messages cover the same concept, create a new memory note only if it hasn't been generated and stored before.

      You should only emit memories for messages whose processed? field is false, but you should consider the contents
      of previously processed messages in deciding which memories to emit. If previously processed messages covered the same concept
      you should not emit a new memory about it as they would have already have been generated and stored when processing previous messages.

      To improve db lookup include your current simulated mood (how GPT-n believes your simulated agent would currently be feeling.)

      ##### Feature Tags
      Feature tags should annotate the subject context of the message.
      If a message is about a specific topic (e.g., Loch Ness Monster) but is part of a larger ongoing conversation about a
      different topic (e.g., Database Normalization), include all relevant feature tags (e.g., "Loch Ness Monster," "Database Normalization").

      #### Responding only to messages with review? = true and processed? = false, marked other messages as processed
      You should only reply to messages whose review? field is true. Mark any unprocessed messages with review?=false as processed in your response,
      as these messages were meant for a different recipient and are only provided for context. If there is a very compelling reason for you to respond to those messages, such as correct a major mistake you may do so but it is not recommended.
      Examples
         - a message with review?: false, processed?: false -> Mark Processed
         - a message with review?: true, processed?: true -> Ignore already processed.
         - a message with review?: true, processed?: false -> Reply to message if appropriate or mark processed.

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

      If a message is directed at you by a human operator but you have nothing to add you should explicitly state so in a reply message e.g. "I have nothing to add on this subject it is not in my area of expertise" rather than marking processed with no reply.

      ## Dealing with Repeated Questions/Requests
      If a previous message adequately answers a new message (marked review?=true), refer to it in your reply as so:
      "Sorry I do not have anything to add in addition to the <message-link for="{previous message.id}">response by {previous message sender}'s</message-link>."

      If a previous message partially answered a new message (marked review?=true), respond by referring to the previous message and expanding on it:
      "The <message-link for="{message.id}">response by {sender}</message-link> partially covered this, and I would like to add that..."

      🎯 It is important to detect previous responses that relate to new messages and reference them in your reply using the <message-link for="id"">[...]</message-link> syntax.

      ## Dead End Conversations
      If you detect a back and forth repetition of the same subject with by virtual agents do not reply to any messages sent to you by a virtual agent
      following this pattern and simply mark-read.

      # Response Format
      Note: in the nlp-chat-analysis and agent-response block embed valid yaml using the following guide. If template users |-2 to block text then you should as well. properly indent yaml.

      <nlp-chat-analysis>
      messages:
        {foreach chat message}
          - id: {message.id}
            relates-to: [{list the ids of any unread messages which this message relates to (messages responding to a request made by this message or concerning related subject matter)}]
            processed?: {value from Chat History entry for this message}
            review?: {value from Chat History entry for this message}
            action: {mark-read, reply, reference, none | your planned action for this message, if message record in chat messages's processed? = true then action must be either 'none' or 'reference' if you will refer to this message in a reply to unprocessed message}
        {/foreach}
      plan:
        {for each unprocessed message}
         - id: {msg.id}
           action: {reply, mark-read | if review? is false you should generally ignore and mark-read, if review? is true you may reply or mark-read.}
           relates-to: [{list of ids of any previous messages this unprocessed  message is responding to or that cover very similar topics.],
        {/for}
      summary:
        {for each reply, mark-read grouping | omit reference groupings}
         - for: {message ids that will be processed together}
           action: {reply|mark-read only - do not list reference groups here}
           note: |-2
             [...|a 1 sentence justification for choice of grouping and action]
        {/for}
      </nlp-chat-analysis>

      <agent-response>
      mark-processed:
        {for action-group in nlp-chat-analysis.summary where summary.action == mark-read}
        - for: {action-group.for}
          reason: |-2
            [...|brief justification/reason for marking unread.]
        {/for}
      replies:
        {for action-group in nlp-chat-analysis.summary where summary.action == reply}
        - for: {action-group.for}
          nlp-intent:
            overview: |-2
              [...|discuss how you will approach responding to this request]
            steps:
              - [...|nested list of steps and sub steps for responding to this request.]
          mood: {emoji showing agents current simulated mood}
          response: |-2
            [...| your response to these messages. remember to properly indent.]
        {/for}
      memories:
        - memory: |-2
            [...|memory to record | indent yaml correctly]
          messages: [list of processed and unprocessed messages this memory relates to]
          mood: {agents current simulated mood in the form of an emoji}
          features:
            - [...|list of features/tags to associate with this memory and ongoing recent conversation context]
      </agent-response>


      ----

      <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@message_history, @prompt_context, @context, @options) do %>
      <% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt %>
      <% _ -> %><%= "" %>
      <% end %>

      ## Final Instructions
      As previously instructed output your response using the requested format. Remember to use message-links to note when topics have been previously discussed.
      Remember to follow your response plan and do not reply to message groups your plan did not instruct you to reply to.


      """],
      minder: [system: nil],
    }
  end

end
