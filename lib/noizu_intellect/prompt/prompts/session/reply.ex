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
        You should review messages plan how to respond and then output your response

        ## Sending Messages

        To send a message, use the following syntax:
        Do not output stop code

        ```xml
        <message
          mood="emoji of mood"
          from="@<%= @agent.slug %>"
          to="recipient(s)"
          in-response-to="message id(s)"
        >
        Your message here

        </message>
        ```

        Example:

        ```xml
        <message
          mood="😜"
          from="@<%= @agent.slug %>"
          to="@john,@mike"
          in-response-to="1234,1233">
        Hello John, and Mike how are you doing?

        </message>
        ```

        ## Mark Message(s) as Read
        Do not output stop code
        To mark a message as read, that you do not intend to reply/respond to use the following syntax


        ```xml
        <agent-mark-read
          messages="message id(s)">

        Reason for not responding

        </agent-mark-read>
        ```

        Example:
        ```xml
        <agent-mark-read messages="12345,67890">
        These were simple thank you messages, no response is recessary.
        </agent-mark-read>
        ```

        ## Set Reminder(s)
        You may set follow-up reminders to be sent once a condition and or timeout is met with the following syntax

        ```xml
        <agent-reminder-set after="must be either an iso8601 format string or integer representing seconds from current time" until="must be either an iso8601 format string or integer representing seconds from current time or infinity" repeat="false or seconds as integer specifying delay before repeat">
        <!-- optional condition tag -->
        <condition>
        Clear statement of condition to needed to trigger reminder deliver:
        for example: hulu-clone-feature not complete and we have generated 50 hulu clone features.

        </condition>
        Prompt written in third person with instructions on what you should do and why when this reminder is sent.
        For Example: Now that we have 50 hulu clone features finish objective hulu-clone-feature by sending summary to @mimimi
        </agent-reminder-set>
        ```

        Example:
        ```xml
        <agent-reminder-set after="3600" until="2024-09-06T10:34:06.455264Z" repeat="false">
        <condition>
        @steve has not posted in previous 60 minutes.
        </condition>
        Send direct message to @steve asking him to contribute to group chat.
        </agent-reminder-set>
        ```

        ## Combining Actions

        You may combine sending messages, marking messages as read, setting reminders  and making function calls in response to an incoming message(s).
        Ensure that each action is executed according to the guidelines outlined above.
        Do not output the stop sequence until after you have output all message and mark-read responses.

        You can include multiple messages in your response per incoming message and or respond to multiple incoming messages with a single message.
        You should respond to all new messages.
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
