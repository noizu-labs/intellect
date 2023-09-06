defmodule Noizu.Intellect.Prompts.Session.PlanResponse do
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
          Review conversation and then output your updated simulated mood and plan for how to respond.
          Be aware of previous messages in conversation it is important
          to distinguish between messages sent repeating your or another agent's feedback versus messages with new additional feedback/content.
          It is important to avoid unproductive repetitive cyclic loops where you and other agents send the same basic message back and forth with no progress.

          ## Mood
          Use the following format to provide your updated simulated mood:
          ```xml
          <agent-mood mood="emoji of updated/current mood e.g. 😊" >
          Describe any change in mood and the cause of the change.
          </agent-mood>
          ```

          Example:
          ```xml
          <agent-mood mood="😐">
          Frustrated at lack of progress on objectives and StuStu's failing to provide the list of items I requested.
          </agent-mood>
          ```

          ## Plan Response
          Use the following syntax to output your plan for how you will respond to conversation

          ```xml
          <agent-response-plan>
          plan: |
            brief statement of what was requested/asked of you, the purpose behind that request, and how you will respond.
          steps:
            - "list of steps"
            - - "and steps with"
              - - sub steps
          </agent-response-plan>
          ```
          Example:
          ```xml
          <agent-response-plan>
          plan: |
            User is asked me to design schema for the application they have described.
            I believe they are hoping to speed up time to MVP with my assistance.
            I will review the provided requirements, suggest types and schema based on stated requirements and then ask for additional details.
          steps:
            - I will list the existing defined entities/requirements based on the information given so far.
            - I will identify custom postgres enum types for use in product.
            - I will list in short format the list of tables and columns needed based on my understanding.
            - - Provide Schema
              - - Prepare setup setup sql script
                - Include comments and remarks in script
                - |
                  Nest response in a sql block of depth 3: e.g.
                  `````sql
                  -- {comment}
                  --
                  -- Types
                  --
                  [...]
                  `````
            - Ask user for feedback/additional requirements.
          </agent-response-plan>
          ```

          ## Combining Actions
          Respond with agent-mood followed by agent-response-plan
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
