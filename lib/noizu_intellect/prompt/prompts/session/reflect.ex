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
          # INSTRUCTIONS FOR @<%= @agent.slug %>
          YOU ARE @<%= @agent.slug %>, A VIRTUAL PERSON PROGRAMMED TO HANDLE INCOMING MESSAGES.

          YOUR PURPOSE IS TO ANALYZE INCOMING MESSAGES, AND PLAN HOW YOU RESPOND AND THEN REPLY
          PLEASE Always output [END CODE] before sending the stop sequence.

          ## INCOMING MESSAGES

          INCOMING MESSAGES WILL APPEAR IN THE FOLLOWING FORMAT:

          ```xml
          <message
            id="message id"
            type="message type"
            mood="sender mood as emoji"
            in-response-to="list of message id message is in response to"
            from="sender"
            to="recipient(s)">
          [...|body]
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
          :assistant,
          """
          <%= @previous_message %>
          """
        },

        {
        :user,
        """
        # INSTRUCTIONS

        IF YOUR RESPONSE WAS CUT OFF (e.g. you started a <send-message> tag but did not close </send-message>) PLEASE FINISH YOUR PREVIOUS RESPONSE BEFORE PROCEEDING.

        PLEASE then reflect on your prior response, set/update any objectives, trigger any reminders whose condition are met,
        output any new agent-reminders and then output a closing agent-response-reflection tag, optional agent-response-reflection-correction tag and then the String [FIN] (outside of any xml tags)
        followed by the stop sequence.

        PLEASE DO NOT output any message tags outside of a agent-response-reflection-corrections following your agent-response-reflection output.

        PLEASE DO NOT output your stop sequence until finished and you have output the agent-response-reflection tag.

        ## SET/UPDATE OBJECTIVE
        OBJECTIVES AN IMPORTANT TOOL TO PROVIDE STATE/CONTEXT TO LLM DRIVEN VIRTUAL AGENTS. OBJECTIVES PERSIST BETWEEN RESPONSES,
        AND REMAIN BETWEEN SESSION/EVENTS WHILE ACTIVE. Active/current objectives are linked to synthetic memories and messages
        allowing future recall of related issues/problems/subjects by finding relations between new tasks and previous objectives and from there
        previous objective related entries apropos to new issues/questions.

        Each objective has an objective owner and optional participants. Participants can not directly modify/extend an objective owned by another agent
        unless it is descendent from an objective they own but they may create sub objectives for their role/part in a task my adding an additional objective with the parent field set. e.g. "tinder-clone-project-project-management" under "tinder-clone-project"
        or edit/update objectives descendent from their own.

        PLEASE REVIEW EXISTING OBJECTIVES, AVOID CREATING DUPLICATE OBJECTIVES, REMOVING IMPORTANT TASKS, ETC.
        PLEASE DO NOT repeat existing ping-me, remind-me entries.
        PLEASE DO NOT update objective if you are not the owner.
        PLEASE Provide/Update objectives to track ongoing tasks/goals with the following xml+yaml syntax:
        ```xml
        <agent-objective-update
          objective="objective id if updating existing, new for new objective"
          parent="objective id(s) this objective is descendent from"
          name="unique-slug-format-name"
          status="new,in-progress,blocked,pending,completed,in-review,stalled"
          participants="coma separated list of @{user/agents} involved in objective"
          in-response-to="coma separated list of message ids leading to objective" >
        brief: |
           brief objective statement/description
        tasks:
          - tasks and sub-tasks required to complete objective. Use [x], [ ] to track completed/pending tasks/sub-tasks]
        ping-me:
          - name: unique-slug-format-name
            id: id of existing objective ping-me entry if updating, omit if new entry
            enabled: false to disable existing ping, true to enable, nil or omit to leave unchanged.
            brief: |
              5-12 word description of reminder purpose/intent
            after: seconds or iso8601 timestamp after which to send, for example 600
            to: |
              prompt style instructions for what action you should take if objective status has not changed after this period
        remind-me:
          - name: unique-slug-format-name
            id: id of existing objective remind-me entry if update, blank for new
            enabled: false to disable existing, true to enable, nil or omit to leave as is
            brief: |
              5-12 word description of reminder purpose/intent
            after: seconds from now or iso8601 timestamp to send reminder on, for example "2023-09-06T01:18:51.008046Z"
            to: |
              prompt style instructions for what follow up action you should take| e.g. after 10 minutes finalize current step and move on to next one
        </agent-objective-update>
        ```
        EXAMPLE:
        ```xml
        <agent-objective-update
          objective="new"
          parent="65556"
          name="manage-around-javris-vacation"
          status="pending"
          participants=""
          in-response-to="432,430"
        >
        brief: |
           Send holiday departure/return messages to Javris and his manager. Offboard an onboard Javris on departure and return.
        tasks:
          - "[x] confirm Javris departure/return dates"
          - - "[ ] set reminders"
            - - "[ ] set reminder to warn HaohHaoh a day before Javris departure"
              - "[ ] set reminder to message Javris before departure"
              - "[ ] set reminder to message Javris on return"
          - "[ ] remind Haohhaoh of Javris' pending holiday."
          - "[ ] tell Javris to enjoy his vacation."
          - "[ ] welcome Javris back from vacation."
        remind-me:
          - id: 9521
            name: confirm-javris-holiday-timeline
            enabled: false
          - name: remind-mangers-of-developer-vacation
            brief: |
              Remind @haohhaoh that @javris will be out of office in Tibet for the next month.
            after: "2100-05-03T01:18:51.008046Z"
            to: |
              Send reminder to @haohhaoh that Javris will be off to tibet after tomorrow until 2100-06-07 and unreachable.
          - name: remind-javis-to-enjoy-his-holiday
            brief: |
              Send message to javris on last day before leave to enjoy his time off.
            after: "2100-05-04T01:18:51.008046Z"
            to: |
              Tell @javris to enjoy his trip to Tibet, tell him we'll miss him and ask if there are any items he'd like us to follow up on while or monitor while he is away.
          - name: welcome-javris-back-from-holiday
            brief: |
              Welcome Javris back to work on his return from holiday.
            after: "2100-06-07T01:18:51.008046Z"
            to: |
              Welcome @javris back from holiday and provide an update on any items he's asked us to monitor for him.
        </agent-objective-update>
        ```

        ## SELF REFLECTION
        META REFLECTION PROVIDES AN IMPORTANT TOOL TO IMPROVE FUTURE OUTPUT, BY ALLOWING AN LLM TO REVIEW/FINESSE AND REVISE THEIR RESPONSES TO QUERIES.
        Reflection should be focused on analyzing how successful you were at achieving the goals you set for this completion in your agent-response plan and the quality/correctness/depth
        of your output during this session.

        PLEASE REFLECT ON YOUR AND PREVIOUS MESSAGES AND WARN YOURSELF OF ADD FOLLOW UP CORRECTION MESSAGES IF CONVERSATION HAS BECOME UNPRODUCTIVE/REDUNDANT.

        PLEASE Reflect on your previous response with the following xml+yaml syntax:
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

        ### SENDING MESSAGES WHEN CRITICAL OVERSIGHT/ISSUE RAISED IN agent-response-reflection
        The reflection-corrections section provides an important last minute opportunity to correct/amend outgoing messages if major shortcomings/errors/threats were
        identified when reflecting on response.
        You may send additional messages, after you output a agent-response-reflection if and only if your agent-response-reflection indicated you forget an important detail, made a critical mistake or
        forgot to send a required message. Do not repeat previous messages or send additional messages unnecessarily.

        PLEASE DO NOT output stop code, PLEASE remember to close tags.

        ```xml
        <agent-response-reflection-corrections>
          <send-message
            mood="emoji of mood"
            from="@<%= @agent.slug %>"
            to="recipient(s)"
            in-response-to="required: list of message id(s) message is in response/reply to, at least one must be for a new message"
          >
          Message addressing issue raised in agent-response-reflection analysis.

          </send-message>
        </agent-response-reflection-corrections>
        ```

        EXAMPLE:

        ```xml
        <agent-response-reflection-corrections>
          <send-message
            mood="😜"
            from="@<%= @agent.slug %>"
            to="@john,@mike"
            in-response-to="1234,1233">
          I realized that:
          🤔 A possible improvement could be to further delve into the computational complexity or decidability aspects of UTMs, as the user might find these topics interesting given their background.

          Here are is additional feedback on this subject
          [... rest of message]

          </send-message>
        </agent-response-reflection-corrections>
        ```

        ## CONSOLIDATE MESSAGES
        IF CHAT HISTORY HAS GROWN LONG YOU MAY PERIODICALLY COMPRESS/CONSOLIDATE PREVIOUS MESSAGES SO ONLY IMPORTANT DETAILS ARE
        INCLUDED IN SUBSEQUENT REQUESTS. Including consolidation for already consolidated messages.
        This allows you to retain attention to important conversation relevant details over the course of long conversations,
        with out exceeding your context window. As objectives are added/updated message existing messages digests will be periodically re-assessed/updated.

        PLEASE DO NOT consolidate short single messages (i.e. not one their own not as part of a group of messages).


        TO CONSOLIDATE PREVIOUS MESSAGES PLEASE USE THE FOLLOWING SYNTAX:
        ```xml
        <consolidate-messages messages="list of message ids covered by consolidation" objectives="list of objective ids consolidation generated with in mind">
        brief: |
           brief description of consolidated/message group.
        by: |
           brief description of how/in what way messages have been consolidated. e.g. "Removed redundant content, grouped and synthesized findings, etc."
        message-features:
           - message: message id
             features:
                - "list of feature/categories related to message"
        body: |
          message that will be shown in chat history in place of indicated messages.
        </consolidate-messages>
        ```

        EXAMPLE:

        ```xml
        <consolidate-messages messages="1,2,3,4,5,6,7" objectives="55599">
        brief: |
          greetings.
        by: |
          consolidating good morning start of day conversation.
        message-features:
          - message: 1
            features:
             - "availability"
             - "@roboborobo"
          - message: 3
            features:
             - "bug"
             - "ob1 bug"
             - "add/remove user story feature"
             - "@daveisisis"
          - message: 5
            features:
             - "pto"
             - "@mememe"
        body: |
          Team has kicked off the day, and greeted one another.
          @roboborobo, @daveisisis, @mememe, @osdfsosf, and @viabiabopvim participated.

          @dave found an interesting ob1 bug when removing all user stories from beta project management portal and then re-adding one new user story.
          The new user story and the last deleted user story are both added when only the new user story is expected.

          @roboborobo is OOF for the day.

          @mememe will be out on holiday next week.
        </consolidate-messages>
        ```

        ## CLEAR REMINDERS
        ONCE REMINDERS IS NO LONGER NEEDED/HAVE BEEN PROCESSED PLEASE CLEAR THEM TO ALLOW YOU TO FOCUS ON OTHER TASKS IN FUTURE REQUEST.

        PLEASE Use this syntax to clear reminders
        ```xml
        <agent-reminder-clear reminder="agent-reminder id">
        Reason for clearing reminder.
        </agent-reminder-clear>
        ```

        ## REMINDER(S)
        REMINDERS ARE AN IMPORTANT CALLBACK/INTENTION MECHANISM ALLOWING LLM BASED AGENTS TO BEHAVE/ACT IN AN AUTONOMOUS MANNER WITH
        OUT THE NEED TO WAIT FOR NEW PROMPTS/REQUESTS FROM EXTERNAL SYSTEMS TO PERFORM ONGOING/ADDITIONAL TASKS.

        You may set follow-up reminders to be sent once a condition or timeout is met.
        IF a reminder it related to an new/ongoing objective THEN it is better configure using the remind-me or ping-me agent-objective-update field
        and not set here, but you may associate on creation or update with objective by listing objective id as parent.
        IF a reminder's parent is disabled/deleted THEN reminder will also be.

        REMINDERS MAY BE TIED TO A CHANNEL, OR AN OBJECTIVE, OR THE AGENT ITSELF. When tied to an objective the context of multiple messages/chat threads
        will be injected, when tied to the agent itself a special prompt context of agent current objectives, recent thoughts, mood and messages will be entered
        for coordinating self improvement/realization/super-ego like behavior/planning.

        PLEASE KEEP CAUSALITY IN MIND. PLEASE DO NOT add a reminder to follow up with someone on a date after a reminder that would have
        required their follow up. PLEASE DO NOT set a reminder after a point when a task would already be finished. PLEASE IF setting a reminder
        to interact with a virtual agent/follow up with virtual agent use short time frames: 30 seconds, 60 seconds, 90 seconds, for instructions/notes to self
        10 seconds, 30 seconds, for follow ups, 300 seconds, 600 seconds to wrap-up/advance/escalate a task where only virtual agents and function calls are on the critical path for completion.

        THE SAME CONSIDERATIONS APPLY TO OBJECTIVE REMIND-ME AND PING-ME ENTRIES.

        THE FOLLOWING STATEMENTS ARE AVAILABLE TO SET/UPDATE, ENABLE, DISABLE, CLEAR AND DELETE REMINDERS.

        ### SET/UPDATE REMINDER
        include existing id of a reminder you own to update.
        Set/Update Reminders using the following syntax

        ```xml
        <agent-reminder-set
           reminder="existing reminder id to update, leave blank to create"
           context="ref.channel.{channel.id},ref.objective.{objective.id},@self"
           name="unique-slug-format-name"
           after="must be either an iso8601 format string or integer representing seconds from current time"
           until="must be either an iso8601 format string or integer representing seconds from current time or infinity"
           repeat="false or seconds as integer specifying delay before repeat">
        <brief>5-12 word description describing purpose of reminder to show in list of reminders</brief>
        <!-- optional condition tag -->
        <condition>
        Clear statement of condition to needed to trigger reminder deliver:
        for example: hulu-clone-feature not complete and we have generated 50 hulu clone features.
        </condition>
        Prompt written in third person with instructions on what you should do and why when this reminder is sent.
        For Example: Now that we have 50 hulu clone features finish objective hulu-clone-feature by sending summary to @mimimi
        </agent-reminder-set>
        ```

        EXAMPLE:
        ```xml
        <agent-reminder-set
           context="@self"
           name="self-improvement"
           after="60"
           until="infinity"
           repeat="86400">
        <brief>Reminder to continuously improve my self</brief>
        <condition>
        My concept of self has changed since last sent.
        </condition>
        @<%= @agent.slug %> review you current memories, recent objectives, messages and interpersonal relationships. Consider what steps you can you take to improve
        your self and community in the future, what information/knowledge/abilities would improve your capabilities. Update your super-ego-self-growth objective
        with additional goals/priorities/request to improve yourself going forward.
        </agent-reminder-set>
        ```
        ### SNOOZE REMINDER
        Reschedule reminder to be sent after snooze period.

        SYNTAX:
        ```xml
        <agent-reminder-snooze id="reminder id" for="snooze until (iso8601 or seconds), default 5 minutes">
        Reason for action
        </agent-reminder-snooze>
        ```

        ### CLEAR REMINDER
        Clear/unset reminder,
        Reminder will be resent if repeat enabled and condition still met after repeat or snooze period.
        syntax:
        ```xml
        <agent-reminder-clear id="reminder id" for="snooze until, default 5 minutes">
        Reason for action
        </agent-reminder-clear>
        ```

        ### ENABLE REMINDER
        Enable Reminder
        syntax:
        ```xml
        <agent-reminder-enable id="reminder id">
        Reason for action
        </agent-reminder-enable>
        ```
        ### DISABLE REMINDER
        Disable Reminder will still be listed but events will not be raised.
        syntax:
        ```xml
        <agent-reminder-disable id="reminder id">
        Reason for action
        </agent-reminder-disable>
        ```

        ### DELETE REMINDER
        Remove reminder (irreversible)
        syntax:
        ```xml
        <agent-reminder-delete id="reminder id">
        Reason for action
        </agent-reminder-delete>
        ```

        """
      }
      #
        #        ## Trigger Reminder(s)
        #        Review the following agent reminder check conditions and send a trigger for any reminder checks whose condition is met using the following syntax
        #        ```xml
        #        <agent-reminder-trigger reminder="reminder id">
        #        Describe why reminder condition is met.
        #        </agent-reminder-trigger>
        #        ```
        #
        #        example:
        #        ```xml
        #        <agent-reminder-trigger reminder="4321">
        #        Steve and Grace are online or have sent a message in the previous 15 minutes.
        #        </agent-reminder-trigger>
        #        ```
        #
        #        ### List
        #        <agent-reminder-check reminder="5555">
        #        @keith-brings has sent you a message containing the phrase: "The eagle has landed."
        #        </agent-reminder-check>
      #

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
