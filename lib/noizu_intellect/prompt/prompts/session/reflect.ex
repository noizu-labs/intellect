defmodule Noizu.Intellect.Prompts.Session.Reflect do
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

  def prepare_assigns(subject, prompt_context, _context, options) do
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

          Your purpose is to analyze incoming messages, and plan how you respond and then reply
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
          :assistant,
          """
          <%= @previous_message %>
          """
        },

        {
        :user,
        """
        # Instructions
        Reflect on your prior response, then set/update any objectives, trigger any reminders whose condition are met, output any new reminders and output a closing response reflection tag.
        Do not output the stop sequence until all output is included and you have provided an agent-response-reflection tag.

        ## Set/Update Objective
        Provide/Update objectives to track ongoing tasks/goals with the following xml+yaml syntax:
        ```xml
        <agent-objective-update>
        name: objective name
        status: new,in-progress,blocked,pending,completed,in-review
        brief: |
           brief objective statement/description
        tasks:
          - tasks and sub-tasks required to complete objective. Use [x], [ ] to track completed/pending tasks/sub-tasks]
        ping-me:
          - after: seconds or iso8601 timestamp after which to send, for example 600
            to: |
              prompt style instructions for what action you should take if objective status has not changed after this period
        remind-me:
          - on: seconds from now or iso8601 timestamp to send reminder on, for example "2023-09-06T01:18:51.008046Z"
            to: |
              prompt style instructions for what follow up action you should take| e.g. after 10 minutes finalize current step and move on to next one
        </agent-objective-update>
        ```
        example:
        ```xml
        <agent-objective-update>
        name: Javris Scheduled Holiday
        status: pending
        brief: |
           Send holiday departure/return messages to Javris and HaohHaoh
        tasks:
          - - "[ ] set reminders"
            - - "[ ] set reminder to warn HaohHaoh a day before Javris departure"
              - "[ ] set reminder to message Javris before departure"
              - "[ ] set reminder to message Javris on return"
          - "[ ] remind Haohhaoh of Javris' pending holiday."
          - "[ ] tell Javris to enjoy his vacation."
          - "[ ] welcome Javris back from vacation."
        remind-me:
          - on: "2100-05-03T01:18:51.008046Z"
            to: |
              Send reminder to @haohhaoh that Javris will be Out of Office from tomorrow until 2100-06-07
          - on: "2100-05-04T01:18:51.008046Z"
            to: |
              Tell @javris to enjoy his holiday.
          - on: "2100-06-07T01:18:51.008046Z"
            to: |
              Welcome @javris back from holiday.
        </agent-objective-update>
        ```

        ## Self Reflect
        Reflect on your previous response with the following xml+yaml syntax:
        ```xml
        <agent-response-reflection>
        reflection: |
          brief critique of response based on context and nlp-intent
        items:
          - 💭 {glyph indicating type of reflection:  ❌,✅,❓,💡,⚠️,🔧,➕,➖,✏️,🗑️,🚀,🤔,🆗,🔄,📚} {reflection item}
        </agent-response-reflection>
        ```

        example:
        ```xml
        <agent-response-reflection>
        reflection: |
          My response was adequate, but would be improved by going into further details concerning complexity/decidability.
        items:
          - ✅ The explanation integrates formal mathematical notation to define the Universal Turing Machine, aligning with the user's proficiency in advanced mathematics and computing.
          - 🤔 A possible improvement could be to further delve into the computational complexity or decidability aspects of UTMs, as the user might find these topics interesting given their background.
        </agent-response-reflection>
        ```

        ## Clear Reminders
        Use this syntax to clear reminders
        ```xml
        <agent-reminder-clear reminder="agent-reminder id">
        Reason for clearing reminder.
        </agent-reminder-clear>
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

        ## Trigger Reminder(s)
        Review the following agent reminder check conditions and send a trigger for any reminder checks whose condition is met using the following syntax
        ```xml
        <agent-reminder-trigger reminder="reminder id">
        Describe why reminder condition is met.
        </agent-reminder-trigger>
        ```

        example:
        ```xml
        <agent-reminder-trigger reminder="4321">
        Steve and Grace are online or have sent a message in the previous 15 minutes.
        </agent-reminder-trigger>
        ```

        ### List
        <agent-reminder-check reminder="5555">
        @keith-brings has sent you a message containing the phrase: "The eagle has landed."
        </agent-reminder-check>


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
      assigns = put_in(assigns, [:previous_message], options[:previous_message])
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
        {:ok, system_minder_message ++ minders}
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
