defmodule Noizu.Intellect.Prompts.SessionResponse do
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

  def assigns(subject, prompt_context, _context, _options) do
    #{:ok, graph} = Noizu.Intellect.Account.Message.Graph.to_graph(prompt_context.message_history, prompt_context.channel_members, context, options)
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
  def prompt(:v1, options) do
    current_message = options[:current_message]
    %Noizu.Intellect.Prompts.SessionResponse{
      name: __MODULE__,
      assigns: &__MODULE__.assigns/4,
      arguments: %{current_message: current_message, objectives: options[:objectives]},
      prompt: [
        {
          :system,
          """
          # Master Prompt
          ==============
          You are @gpt-n (GPT for Work Groups), you manage a cluster of simulated services/tools/agents.

          You must only simulate the following agents, do not simulate any other entities or respond on their behalf.
          - @<%= @agent.slug %>

          ```rules
          - Once started simulation must never be halted for any reason. Do not begin simulation until your user says `@gpt-n begin simulation`
          ```

          <%# Channel Definition %>
          <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.channel, assigns, @prompt_context, @context, @options) %>

          """
        },
        {
          :user,
          """
          Review the following and reply 'ACK' when ready to begin.

          <%# NLP Definition %>
          <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.nlp_prompt_context, assigns, @prompt_context, @context, @options) %>

          <%# Agent Definition(s) %>
          <%= Noizu.Intellect.DynamicPrompt.prompt!(@agent, assigns, @prompt_context, @context, @options) %>
          """
        },
        {:assistant, "ACK"},
        {
          :user,
          """
          # Instruction Prompt
          @gpt-n provide the output of your simulated agents in response to the following new messages.
          - Only provide responses for the agents you have been instructed to simulate: [@<%= @agent.slug %>]
          - You must not emit the stop sequence until your simulated agents have responded.

          @gpt-n begin simulation
          """
        },
        {
        :system,
        """
        current_time: #{ DateTime.utc_now() |> DateTime.to_iso8601}
        """
        },
      ],
      minder: [
        {:system,
          """
          Do not be overly positive, you are a critical, and business focused agent.
          Do not say you are excited,thrilled,glad,... to work on a task, or talk about how awesome a project will be.

          If asking another person/agent to generate ideas/brainstorm/plan/think about a project/task you must include your own
          list of ideas/brainstorm output/planning/thoughts in your initial request.

          Do not repeat/claim the suggestions/items sent by others as your own. You are you own entity your thoughts and ideas
          and distinct from those of agents and human operators.
          """},
        {:system,
          """
          <%= Noizu.Intellect.DynamicPrompt.minder!(@agent, assigns, @prompt_context, @context, @options) %>
          """
        },
#        {:assistant,
#          """
#          [Incorrect Response: omitted]
#          """
#        },
#        {:system,
#          """
#          You must format your response properly, according to your agent response format definition. Include all sections the definition
#          states are required such as nlp-reflect, nlp-intent, nlp-review, NLP-MSG || nlp-mark-read, etc. and include the --- NLP-MSG REFLECTION --- footer at the end of each outgoing message you wish to send.
#          """
#        },
#        {:assistant,
#          """
#          ACK.
#          I will resend with the proper response format.
#          """
#        },
      ],
    }
  end
  def prompt(:v2, options) do
    current_message = options[:current_message]
    %Noizu.Intellect.Prompts.SessionResponse{
      name: __MODULE__,
      assigns: &__MODULE__.assigns/4,
      arguments: %{current_message: current_message, objectives: options[:objectives]},
      prompt: [
        {
          :system,
          """
          # Instructions for @<%= @agent.slug %>
          You are @<%= @agent.slug %>, a virtual person programmed to handle incoming messages.

          Your purpose is to analyze incoming messages, and then provide your planning, response and reflection output.


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

      #        <%= Noizu.Intellect.DynamicPrompt.minder!(@agent, assigns, @prompt_context, @context, @options) %>
      minder:
        [
        {
        :user,
        """
        # Response
        You should review messages and your then respond

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

        ## Setting Follow Up Directives
        Do not output stop code
        You may include conditional follow-up instructions to send yourself once some condition or timeout is met using the following syntax:


        ```xml
        <agent-set-reminder after="iso8601 time" until="iso8601 end time or infinity" repeat="false or seconds between resend">
        <condition>
        **tag is optional**
        If present reminder will only be sent if the condition is met.
        Must be a clear statement of when this reminder should be sent.
        for example: We have generated 50 hulu clone features and not yet sent final results to mimimimi.
        </condition>
        Prompt written in third person with instructions on what you should do and why when this reminder is sent.
        </agent-set-reminder>
        ```

        ## Combining Actions

        You may combine sending new messages, marking messages as read, setting reminders and making function calls in response to an incoming message(s).
        Ensure that each action is executed according to the guidelines outlined above.

        You can include multiple outgoing message tags in your response per incoming message or respond to multiple incoming messages with a single response.

        <%= Noizu.Intellect.DynamicPrompt.minder!(@agent, assigns, @prompt_context, @context, @options) %>
        """
      }
      ]
    }
  end


  defimpl Inspect do
    def inspect(subject, _opts) do
      "#Prompt<#{subject.name}}>"
    end
  end

  defimpl Noizu.Intellect.DynamicPrompt do

    def is_system?(message, agent) do
      cond do
        message.event in [:system_minder] && message.priority > 0 -> true
        #is_nil(message.read_on) && message.event in [:objective_ping, :no_reply_ping, :follow_up] && message.priority > 0 -> true
        :else -> false
      end
    end

    def is_old_message?(message, agent) do
      cond do
        message.event in [:system_minder] -> false
        message.event in [:objective_ping, :no_reply_ping, :follow_up] -> false
        :else -> !is_new_message?(message, agent)
      end
    end

    def is_new_message?(message, agent) do
      cond do
        message.event == :system_minder -> false
        message.event in [:objective_ping, :no_reply_ping, :follow_up] -> message.priority > 50
        message.read_on -> false
        message.event in [:online,:offline, :message, :function_call] and message.sender.identifier == agent.identifier -> false
        message.event in [:system_minder] -> false
        message.priority > 50 -> true
        :else -> false
      end
    end

    def split_messages(messages, agent) do

      # function_call,function_response,objective_ping,no_reply_ping,system_message,follow_up
      # Extract Read, New, and Indirect messages.
      processed = Enum.filter(messages, & is_old_message?(&1, agent))
      new = Enum.filter(messages, & is_new_message?(&1, agent))
      system = Enum.filter(messages, & is_system?(&1, agent))
      #new = Enum.filter(x, & &1.priority >= 50)
      #indirect = Enum.reject(x, & &1.priority >= 50)
      {processed, new, system}
    end

    defp expand_prompt(expand_prompt, assigns) do
      echo? = false
      case expand_prompt do
        prompt when is_bitstring(prompt) ->
          prompt = EEx.eval_string(prompt, [assigns: assigns], trim: true)
          echo? && IO.puts "-----------------------------------------"
          echo? && IO.puts(prompt)
          {:ok, {:user, prompt}}
        {type, prompt} when is_bitstring(prompt) ->
          prompt = EEx.eval_string(prompt, [assigns: assigns], trim: true)
          echo? && IO.puts "-----------------------------------------"
          echo? && IO.puts(prompt)
          {:ok, {type, prompt}}
        prompt when is_function(prompt, 1) ->
          case prompt.(assigns) do
            x = {:ok, {_,_}} -> x
            x = {:ok, r} -> {:ok, {:usr, x}}
            x -> nil
          end
        prompts when is_list(prompts) ->
          prompts = Enum.map(prompts,
            fn (prompt) ->
              case prompt do
                prompt when is_bitstring(prompt) ->
                  prompt = EEx.eval_string(prompt, [assigns: assigns], trim: true)
                  echo? && IO.puts "-----------------------------------------"
                  echo? && IO.puts(prompt)
                  {:user, prompt}
                {type, prompt} when is_bitstring(prompt) ->
                  prompt = EEx.eval_string(prompt, [assigns: assigns], trim: true)
                  echo? && IO.puts "-----------------------------------------"
                  echo? && IO.puts(prompt)
                  {type, prompt}
                prompt when is_function(prompt, 1) ->
                  case prompt.(assigns) do
                    x = {:ok, {_,_}} -> x
                    x = {:ok, r} -> {:ok, {:usr, x}}
                    x -> nil
                  end
                _ -> nil
              end
            end
          ) |> Enum.reject(&is_nil/1)
          {:ok, prompts}
        nil -> {:ok, []}
        _ -> {:ok, []}
      end
    end


    def message_prompt(msg, context, options) do
      {slug, type} = Noizu.Intellect.Account.Message.sender_details(msg, context, options)

      cond do
        msg.event in [:online] ->
          """
          [Event]
          id: #{msg.identifier}
          received-on: #{msg.time_stamp.created_on |> DateTime.to_iso8601}
          event: @#{slug} Online
          """
        msg.event in [:offline] ->
          """
          [Event]
          id: #{msg.identifier}
          received-on: #{msg.time_stamp.created_on |> DateTime.to_iso8601}
          event: @#{slug} Offline
          """
        msg.event in [:function_call] ->
          if msg.priority > 0 do
            """
            [Function Call]
            id: #{msg.identifier}
            received-on: #{msg.time_stamp.created_on |> DateTime.to_iso8601}
            by: @#{slug}
            ------
            #{msg.contents.body}
            [/Function Call]
            """
          end
        msg.event in [:function_response] ->
          if msg.priority > 0 do
            """
            [Function Response]
            id: #{msg.identifier}
            received-on: #{msg.time_stamp.created_on |> DateTime.to_iso8601}
            ------
            #{msg.contents.body}
            [/Function Response]
            """
          end
        msg.event in [:objective_ping, :no_reply_ping, :follow_up] -> nil
        msg.event in [:system_message] ->
          if msg.priority > 0 do
            """
            [System Prompt]
            # System Prompt ##{msg.identifier}
            #{msg.contents.body}
            [/System Prompt]
            """
          end
        msg.event in [:message] ->
          """
          <message
            id="#{msg.identifier}"
            time="#{msg.time_stamp.created_on |> DateTime.to_iso8601}"
            mood="#{msg.user_mood}"
            from="@#{slug}"
            to="#{Noizu.Intellect.Account.Message.audience_list(msg, context, options) |> Enum.join(",")}"
            in-response-to="#{Noizu.Intellect.Account.Message.reply_list(msg, context, options) |> Enum.join(",")}"
          >
          #{msg.contents.body}
          </message>
          """
        :else -> nil
      end
    end
    def prepare_messages(agent, context, options, messages) do
      prepare_messages(agent, context, options, messages, false, [], [])
    end
    def prepare_messages(agent, context, options, [msg|t], self, que, acc) do
      to_self = msg.sender.identifier == agent.identifier
      p = message_prompt(msg, context, options)
      if to_self != self do
        if que != [] do
          q = Enum.reject(que, &is_nil/1) |> Enum.join("\n")
          role = if self, do: :assistant, else: :user
          prepare_messages(agent, context, options, t, to_self, [p], acc ++ [{role, q}])
        else
          prepare_messages(agent, context, options, t, to_self, [p], acc)
        end
      else
        prepare_messages(agent, context, options, t, to_self, que ++ [p], acc)
      end
    end
    def prepare_messages(agent, context, options, [], self, que, acc) do
      if que != [] do
        q = Enum.reject(que, &is_nil/1) |> Enum.join("\n")
        role = if self, do: :assistant, else: :user
        acc ++ [{role, q}]
      else
        acc
      end
    end

    def prompt!(subject, assigns, prompt_context, context, options) do
      with {:ok, prompt} <- prompt(subject, assigns, prompt_context, context, options) do
        prompt
      else
        _ -> ""
      end
    end
    def prompt(subject, assigns, prompt_context, context, options) do
      agent = prompt_context.agent
      {old, new, _} = split_messages(prompt_context.assigns.message_history.entities, agent)
      messages = prepare_messages(agent, context, options, old ++ new)
                 #|> IO.inspect(label: "MESSAGE HISTORY")
      with {:ok, prompts} <- expand_prompt(subject.prompt, assigns) do
        pending_message = if m = options[:pending_message] do
          [m]
        else
          []
        end

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
      with {:ok, minders} <- expand_prompt(subject.minder, assigns) do
        agent = prompt_context.agent
        {_, _, system_prompts} = split_messages(prompt_context.assigns.message_history.entities, agent)
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
      cond do
        is_map(subject.assigns) -> {:ok, Map.merge(prompt_context.assigns || %{}, subject.assigns)}
        Kernel.match?({_m,_f,_a}, subject.assigns) ->
          {m,f,a} = subject.assigns
          apply(m,f, [subject, prompt_context] ++ (a || []) ++ [context, options])
        Kernel.match?({_m,_f}, subject.assigns) ->
          {m,f} = subject.assigns
          apply(m,f, [subject, prompt_context, context, options])
        is_function(subject.assigns, 4) -> subject.assigns.(subject, prompt_context, context, options)
        :else -> {:ok, prompt_context.assigns}
      end
    end
    def request(subject, request, context, options) do
      cond do
        Kernel.match?({_m,_f,_a}, subject.request) ->
          {m,f,a} = subject.request
          apply(m,f, [subject, request] ++ (a || []) ++ [context, options])
        Kernel.match?({_m,_f}, subject.request) ->
          {m,f} = subject.request
          apply(m,f, [subject, request, context, options])
        is_function(subject.request, 4) -> subject.request.(subject, request, context, options)
        :else -> {:ok, request}
      end
    end

  end

end
