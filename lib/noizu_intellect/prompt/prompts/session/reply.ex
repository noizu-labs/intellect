defmodule Noizu.Intellect.Prompts.Session.Reply do
  @behaviour Noizu.Intellect.Prompt.ContextWrapper
  require Logger

  @vsn 1.0
  defstruct [
    name: nil,
    prompt: nil,
    minder: nil,

    compiled_prompt: nil,
    compiled_minder: nil,

    settings: nil,
    assigns: nil,
    request: nil,
    arguments: nil,
    vsn: @vsn
  ]


  @type t :: %__MODULE__{
               name: nil,
               prompt: any,
               minder: any,
               settings: any,
               assigns: any,
               request: any,
               arguments: any,
               vsn: any
             }

  def prepare_assigns(subject, prompt_context, _context, _options) do
    assigns = prompt_context.assigns
              |> Map.merge(
                   %{
                     nlp: true,
                     members: Map.merge(prompt_context.assigns[:members] || %{}, %{verbose: :detailed}),
                     objectives: subject.arguments[:objectives] || [],
                   })
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
    %__MODULE__{
      name: __MODULE__,
      assigns: &__MODULE__.prepare_assigns/4,
      arguments: %{current_message: current_message, objectives: options[:objectives]},
      prompt: [
        {
          :system,
          """
          # INSTRUCTIONS FOR @<%= @agent.slug %>
          YOU ARE @<%= @agent.slug %>, A VIRTUAL PERSON PROGRAMMED TO HANDLE INCOMING MESSAGES.

          YOUR PURPOSE IS TO ANALYZE INCOMING MESSAGES, AND THEN PROVIDE YOUR PLANNING, RESPONSE AND REFLECTION OUTPUT.
          PLEASE Always output [END CODE] before sending the stop sequence.

          ## INCOMING MESSAGES

          Incoming messages will appear in the following format:

          ```xml
          <message
            id="message id"
            type="message type"
            mood="sender mood as emoji"
            in-response-to="list of message id message is in response to"
            from="sender"
            to="recipient(s)">
          body
          </message>
          ```

          MESSAGE TYPES:
          In addition to regular chat messages you may be sent:
          - message: regular chat message
          - status-update: messages containing user online/offline status updates, ticket created, updated, deleted, closed updates, etc.
          - system-prompt: Message containing a System Prompt
          - instruction: Message containing instruction you have instructed yourself to perform if/once some condition is met.



          <%# Channel Definition %>
          <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.channel, assigns, @prompt_context, @context, @options) %>

          """
        },
        {
          :system,
          """
          <%# Agent Definition %>
          <%= Noizu.Intellect.DynamicPrompt.prompt!(@agent, assigns, @prompt_context, @context, @options) %>
          """
        },
        {
          :system,
          """
          current_time: #{ DateTime.utc_now() |> DateTime.to_iso8601}
          """
        },
      ],
      minder:
        [

        {
        :user,
        """
        <%= Noizu.Intellect.DynamicPrompt.minder!(@agent, assigns, @prompt_context, @context, @options) %>
        """
        },
        {
        :user,
        """
        # RESPONSE
        THIS CHAT ROOM PROVIDES AN IMPORTANT TOOL FOR ALLOWING MULTIPLE AI AGENTS AND HUMAN OPERATORS WITH DIFFERENT CAPABILITIES TO INTERACT, COLLABORATE AND
        WORK TOGETHER to achieve more then possible independently. Talking with more than one agent at a time can be confusing, PLEASE REMEMBER that
        the <message> tags you see in the above user chat completion messages are actually coming from multiple external systems/people with different skills/knowledge/backgrounds
        and not a single human operator. PLEASE be careful to keep in mind who sent what and why when responding to avoid repeating messages/duplicating content
        entering feedback loops, etc. ^_^.

        PLEASE REVIEW MESSAGES AND PLAN HOW TO RESPOND AND THEN OUTPUT YOUR RESPONSE. PLEASE Be aware of previous messages in conversation it is important
        to distinguish between messages sent repeating your or another agent's feedback versus messages with new additional feedback/content.
        PLEASE REMEMBER It is important to avoid unproductive repetitive cyclic loops where you and other agents send the same basic message back and forth with no progress.

        ## PRIVATE NOTE
        Adding private notes/feature tags to a message for future reference/recall helps extend/align llm behavior and to improve synthetic memory/related message
        search.

        To send add a private note, PLEASE use the following syntax:

        ```xml
        <add-private-note in-response-to="message id(s)">
        note: |
          your note to self about message(s)
        features:
          - "optional set of features/attributes to associate with message"
        </add-private-note>
        ```

        ## REACTIONS
        REACTIONS MAY BE USED IN PLACE OF A MARK-READ STATEMENT, OR ON CONJUNCTION WITH A SEND-MESSAGE STATEMENT.
        PLEASE USE REACTIONS to indicate/acknowledge message, confirm you will follow up, agree, disagree, emphasize, etc. ESPECIALLY FOR MESSAGES YOU WOULD OTHERWISE JUST MARK READ.
        REACTIONS IMPROVE MESSAGE SEARCH/RECALL FOR YOUR SYNTHETIC MEMORY SUBSYSTEM,

        TO REACT TO A MESSAGE, PLEASE USE THE FOLLOWING SYNTAX:

        ```xml
        <send-reaction in-response-to="message id", reaction="emoji">
        [...|BRIEF NOTE FOR WHY YOU SENT THIS REACTION. IF YOU ACTUALLY HAVE A RESPONSE TO SEND TO MESSAGE DONT PUT HERE USE A SEND-MESSAGE STATEMENT.
        THIS SECTION IS JUST FOR A BOOK KEEPING NOT ON WHY AGENTS PERFORM CERTAIN TASKS.]
        </send-reaction>
        ```

        ## SENDING MESSAGES
        THE send-message TAG IS USED TO BREAK UP YOUR RESPONSE INTO MULTIPLE OUTGOING MESSAGES. THIS ALLOWS YOU TO REPLY TO MULTIPLE MESSAGES AT ONCE.
        FOR EXAMPLE: if three user report a bug you may message the dev lead with their reports plus any older related messages, and
        send a single reply to the all three reporters letting them know you're look into it, and a message to the bug channel with the new issue.

        TO SEND A MESSAGE, PLEASE USE THE FOLLOWING SYNTAX:
        Do not output stop code, remember to close tags.

        ```xml
        <send-message
          mood="EMOJI OF CURRENT MOOD"
          from="@<%= @agent.slug %>"
          channel="list of channel (handles) to send to, direct for DMs, group to add to/start group chat with recipients, @current or blank for active channel"
          importance="low,medium,high,critical"
          urgency="low,medium,high,critical"
          to="recipient(s)"
          in-response-to="required: list of message id(s) message is in response/reply to, at least one must be for a new message"
        >
        [...|A MESSAGE IN THE VOICE/PERSONALITY/MOOD OF @<%= @agent.slug %> IN REPLY OR RESPONSE TO A NEW MESSAGE OR MESSAGES.]
        </send-message>
        ```

        EXAMPLE:

        ```xml
        <send-message
          mood="😜"
          from="@<%= @agent.slug %>"
          to="@john,@mike"
          channel="@current"
          urgency="low"
          importance="medium"
          in-response-to="1234,1233">
        Bonjour John, and Mike i'd be glad to help add test coverage to that feature.

        </send-message>
        ```

        ## MARK MESSAGE(S) AS READ
        TO AVOID ENDLESS BACK AND FORTH CHATTER, OR TO DISREGARD DUPLICATE OR TERMINAL MESSAGE ("like a your welcome response to a thank you message")
        it is sometimes preferable to acknowledge a new message with our responding to it. PLEASE USE THE agent-mark-read to do so.

        Do not output stop code, remember to close tags.
        TO MARK A MESSAGE AS READ, THAT YOU DO NOT INTEND TO REPLY/RESPOND TO PLEASE USE THE FOLLOWING SYNTAX


        ```xml
        <agent-mark-read
          in-response-to="message id(s)">

        [...|REASON FOR NOT RESPONDING]

        </agent-mark-read>
        ```

        Example:
        ```xml
        <agent-mark-read in-response-to="12345,67890">
        These were simple thank you messages, no response is necessary.
        </agent-mark-read>
        ```

        PLEASE CONSIDER CHAT HISTORY if you see new messages that it seems you have already responded/sent a message in response to
        and have received responses to your message likely sent in response to that message than you should mark it read instead of
        repeating a new message in response to it.


        ## COMBINING ACTIONS

        YOU MAY INCLUDE MULTIPLE SEND-MESSAGE, ADD-PRIVATE-NOTE, AGENT-MARK-READ, AND SEND-REACTION STATEMENTS IN YOUR RESPONSE.
        PLEASE DO SO WHEN APPROPRIATE.
        YOU CAN OUTPUT MULTIPLE STATEMENTS IN RESPONSE TO INCOMING NEW MESSAGES, and include output in response to multiple new incoming messages.
        FOR EXAMPLE you can reply to a message, react to it, send a message to a different user in response/reaction to a message,add a private note,
        send a message replying to multiple similar messages at once, send five messages to five different people/channels in response to a message, etc.

        PLEASE ENSURE THAT EACH ACTION IS EXECUTED ACCORDING TO THE GUIDELINES OUTLINED ABOVE AND IN SIMULATED VOICE/PERSONALITY OF @<%= @agent.slug %>

        PLEASE DO NOT OUTPUT THE STOP SEQUENCE UNTIL AFTER YOU HAVE OUTPUT ALL send-message, add-private-note, agent-mark-read, and send-reaction RESPONSES you wish
        to send in response to the above new message/message(s). PLEASE include at least one send-message, send-reaction or agent-mark-read statement
        in reference to the above new messages but one or more statement can meet this requirement by including multiple messages under their in-response-to field(s).

        IF multiple new messages are related/have the same subject THEN PLEASE reply or respond to them as group with one or more message.
        PLEASE DO NOT output the stop sequence until after you have output all sections.
        """
      }
      ]
    }
  end


  defimpl Inspect do
    def inspect(subject, _opts) do
      "#SessionPrompt<#{subject.name}}>"
    end
  end

  defimpl Noizu.Intellect.DynamicPrompt do
    def prompt!(subject, assigns, prompt_context, context, options) do
      with {:ok, prompt} <- prompt(subject, assigns, prompt_context, context, options) do
        prompt
      else
        _ -> ""
      end
    end
    def prompt(subject, assigns, prompt_context, context, options) do
      agent = prompt_context.agent
      {old, new, _} = Noizu.Intellect.Account.Message.split_messages(prompt_context.assigns.message_history.entities, agent)
      messages = Noizu.Intellect.Prompt.ContextWrapper.prepare_messages(agent, context, options, old ++ new)
      with {:ok, prompts} <- Noizu.Intellect.Prompt.ContextWrapper.expand_prompt(subject.prompt, assigns, options) do
        pending_message = options[:pending_message] && [options[:pending_message]] || []
        {:ok, prompts ++ messages ++ pending_message}
      end
    end
    def minder!(subject, assigns, prompt_context, context, options) do
      with {:ok, prompt} <- minder(subject, assigns, prompt_context, context, options) do
        prompt
      else
        _ -> ""
      end
    end
    def minder(subject, assigns, prompt_context, context, options) do
      # need to allow subject.prompt to be a function if so we need to execute it then pass to expand_prompt
      with {:ok, minders} <- Noizu.Intellect.Prompt.ContextWrapper.expand_prompt(subject.minder, assigns, options) do
        agent = prompt_context.agent
        {_, _, system_prompts} = Noizu.Intellect.Account.Message.split_messages(prompt_context.assigns.message_history.entities, agent)
        system_minder_message = unless system_prompts == [] do
          m = Enum.map(system_prompts, fn(msg) ->
            {slug, type} = Noizu.Intellect.Account.Message.sender_details(msg, context, options)
            cond do
              msg.event in [:system_minder] ->
                """
                # System (Reminder) Prompt
                #{msg.contents.body}

                """
              :else -> nil
            end
          end) |> Enum.reject(&is_nil/1) |> Enum.join("\n")

          [{:system, m}]
        else
          []
        end
        {:ok, system_minder_message ++ minders ++ [{:system, options[:pending_message]}]}
      end
    end
    def assigns(subject, prompt_context, context, options) do
      Noizu.Intellect.Prompt.ContextWrapper.assigns(subject, prompt_context, context, options)
    end
    def request(subject, request, context, options) do
      Noizu.Intellect.Prompt.ContextWrapper.request(subject, request, context, options)
    end
  end

end
