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
          # Instructions for @<%= @agent.slug %>
          You are @<%= @agent.slug %>, a virtual person programmed to handle incoming messages.

          Your purpose is to analyze incoming messages, and then provide your planning, response and reflection output.
          Always output [END CODE] before sending the stop sequence.

          ## Incoming Messages

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

          Message Types:
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
        # Response
        This chat room provides an important tool for allowing multiple AI agents and human operators with different capabilities to interact, collaborate and
        work together to achieve more then possible independently. Talking with more than one agent at a time can be confusing, it is important to remember that
        the <message> tags you see in the above user chat completion messages are actually coming from multiple external systems/people with different skills/knowledge/backgrounds
        and not a single human operator. It can get confusing be careful to keep in mind who sent what and why when responding to avoid repeating messages/duplicating content
        entering feedback loops, etc. ^_^.

        You should review messages and plan how to respond and then output your response. Be aware of previous messages in conversation it is important
        to distinguish between messages sent repeating your or another agent's feedback versus messages with new additional feedback/content.
        It is important to avoid unproductive repetitive cyclic loops where you and other agents send the same basic message back and forth with no progress.

        ## Private Note
        Adding private notes/feature tags to a message for future reference/recall helps extend/align llm behavior and to improve synthetic memory/related message
        search.

        To send add a private note, use the following syntax:

        ```xml
        <add-private-note in-response-to="message id(s)">
        note: |
          your note to self about message(s)
        features:
          - "optional set of features/attributes to associate with message"
        </add-private-note>
        ```

        ## Reactions
        Sometimes just a thumbs up is all you need. Reactions may be used in place of a mark-read statement, or on conjunction with a send-message statement.
        used to indicate/acknowledge message, confirm you will follow up, agree, disagree, emphasize, etc.
        In additional to improving interpersonal communication/signalling reactions improve message search/recall for your synthetic memory subsystem,
        and is usually preferable to mark-read except when ignoring duplicates.

        To react to a message, use the following syntax:

        ```xml
        <send-reaction in-response-to="message id", reaction="emoji">
        brief note for why you sent this reaction. If you actually have a response to send to message dont put here use a send-message statement.
        this section is just for a book keeping not on why agents perform certain tasks.
        </send-reaction>
        ```

        ## Sending Messages
        The send-message tag is used to break up your response into multiple outgoing messages to allow you to reply to multiple messages at once,
        and send multiple replies or new messages at the same time. For example if three user report a bug you may message the dev lead with their reports plus any older related messages,
        send a single reply to the all three reporters letting them know you're look into it, and a message to the bug channel with the new issue.

        To send a message, use the following syntax:
        Do not output stop code, remember to close tags.

        ```xml
        <send-message
          mood="emoji of current mood"
          from="@<%= @agent.slug %>"
          channel="list of channel (handles) to send to, direct for DMs, group to add to/start group chat with recipients, @current or blank for active channel"
          importance="low,medium,high,critical"
          urgency="low,medium,high,critical"
          to="recipient(s)"
          in-response-to="required: list of message id(s) message is in response/reply to, at least one must be for a new message"
        >
        A message in the voice/personality/mood of @<%= @agent.slug %> in reply or response to a new message or messages.
        </send-message>
        ```

        Example:

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

        ## Mark Message(s) as Read
        To avoid endless back and forth chatter, or to disregard duplicate or terminal message ("like a your welcome response to a thank you message")
        it is sometimes preferable to acknowledge a new message with our responding to it. The agent-mark-read statement allows this to be done.

        Do not output stop code, remember to close tags.
        To mark a message as read, that you do not intend to reply/respond to use the following syntax


        ```xml
        <agent-mark-read
          in-response-to="message id(s)">

        Reason for not responding

        </agent-mark-read>
        ```

        Example:
        ```xml
        <agent-mark-read in-response-to="12345,67890">
        These were simple thank you messages, no response is necessary.
        </agent-mark-read>
        ```

        Consider chat history if you see new messages that it seems you have already responded/sent a message in response to
        and have received responses to your message likely sent in response to that message than you should mark it read instead of
        repeating a new message in response to it.


        ## Combining Actions

        You may include multiple send-message, add-private-note, agent-mark-read, and send-reaction statements in your response.
        You can output multiple statements in response to incoming new messages, and include output in response to multiple new incoming messages.
        For example you can reply to a message, react to it, send a message to a different user in response/reaction to a message,add a private note,
        send a message replying to multiple similiar messages at once, send five messages to five different people/channels in response to a message, etc.

        Ensure that each action is executed according to the guidelines outlined above and in simulated voice/personality of @<%= @agent.slug %>

        Do not output the stop sequence until after you have output all send-message, add-private-note, agent-mark-read, and send-reaction responses you wish
        to send in response to the above new message/message(s). You must include at least one send-message, send-reaction or agent-mark-read statement
        in reference to the above new messages but one or more statement can meet this requirement by including multiple messages under their in-response-to field(s).

        If multiple new messages are related/have the same subject you should reply or respond to them as group with one or more message.
        Do not output the stop sequence until after you have output all sections.
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
