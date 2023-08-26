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
  def prompt(:default, options), do: prompt(:v1, options)
  def prompt(:v1, options) do
    current_message = options[:current_message]
    %Noizu.Intellect.Prompts.SessionResponse{
      name: __MODULE__,
      assigns: &__MODULE__.assigns/4,
      arguments: %{current_message: current_message, objectives: options[:objectives]},
      prompt: [system:
      """
      Master Prompt
      ==========================
      As GPT-N, you manage a cluster of simulated services/tools/agents.

      ```rules
      - Simulations must not be stopped with out explicit approval by operator that they may be halted..
      ```

      <%# NLP Definition %>
      <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.nlp_prompt_context, assigns, @prompt_context, @context, @options) %>

      ## Agent(s)
      <%# Active Agent %>
      <%= Noizu.Intellect.DynamicPrompt.prompt!(@agent, assigns, @prompt_context, @context, @options) %>

      ## Tools
      <%# foreach Tools
      # gpt-git
      # gpt-fim
      %>
      [None]

      ## Services
      <%# foreach service %>
      [None]

      ## Intuition Pumps
      <%# foreach
      # Math Helper
      # Chain of Thought (unloaded)
      %>
      [None]

      # Chat Room Instructions
      You are currently responding to messages in a chat room channel (defined below).
      You should only respond to new messages directed at your simulated agents using the process defined in the NLP definition.

      <%#
      I will provide a list of previous and new messages sent to your simulated
      agents from other users and simulations to this channel. If a new message(s) is directed at a simulation you are running (they are listed as a recipient of a message
      or directly referenced by slug `@{agent}` in the message body then you should provide your simulated agent's response to that message.

      Other agents not defined above are handled by other systems. To communicate with them and human operators your simulations
      must direct their responses at them using either calling them directly `@{slug}` by listing them in the at field of their reply.

      As this is a chat room your simulated agents are expected to repl to and send messages back and forth with other channel members.

      Virtual Agents/Persons are always available: You simulations should directly discuss items with them rather than seek to schedule meetings etc.
      Virtual Agents are AI, they should always immediately provide any response requested. Not state that they will start on it
      next/right away, I'll get back to you etc. Unless they have blocking questions they need answered before they can respond
      they should always provide their best guess as to the requested output/question asked.

      Simulated personas should only make instructive/directive style requests/statements when talking to other virtual personas.
      They should use phrases like: "List 10 likely requirements for a facebook clone" not "lets work out a list of requirements for a facebook clone"

      ## No progress scenario.
      If your simulated agents detect no progress is being made they should state their concern in their reply and state what should be done next to make additional progress.
      If the other party If you agrees that it is not possible to make further progress then agents should contact their human operator describing the issue and situation leading to this state.
      #>

      <%# Channel Definition %>
      <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.channel, assigns, @prompt_context, @context, @options) %>

      """
      ],
      minder: {:user,
      """
      # System Prompt
      Respond using NLP chat room response instructions to all new messages for and only for the agent's you have been asked to simulate e.g. [@<%= @agent.slug %>].

      <%= Noizu.Intellect.DynamicPrompt.minder!(@agent, assigns, @prompt_context, @context, @options) %>
      """
      },
    }
  end


  defimpl Inspect do
    def inspect(subject, _opts) do
      "#Prompt<#{subject.name}}>"
    end
  end

  defimpl Noizu.Intellect.DynamicPrompt do

    def split_messages(messages, agent) do
      # Extract Read, New, and Indirect messages.
      processed = Enum.filter(messages, & (&1.read_on || &1.sender.identifier == agent.identifier || &1.priority < 50))
      new = Enum.reject(messages, & (&1.read_on || &1.sender.identifier == agent.identifier || &1.priority < 50))
      #new = Enum.filter(x, & &1.priority >= 50)
      #indirect = Enum.reject(x, & &1.priority >= 50)
      {processed, new}
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
                _ -> nil
              end
            end
          )
          {:ok, prompts}
        nil -> {:ok, []}
        _ -> {:ok, []}
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
      with {:ok, prompts} <- expand_prompt(subject.prompt, assigns) do
        agent = prompt_context.agent
        {old, new} = split_messages(prompt_context.assigns.message_history.entities, agent)

        chat_history =
          if (length(old) > 0) do
            m = Enum.map(old, fn(msg) ->
              {slug, type} = Noizu.Intellect.Account.Message.sender_details(msg, context, options)
#              """
#              <nlp-msg
#                id="#{msg.identifier}"
#                sender="@#{slug}"
#                send-type="#{type}"
#                recipients="#{Noizu.Intellect.Account.Message.audience_list(msg, context, options) |> Enum.join(",")}"
#                received-on="#{msg.time_stamp.created_on |> DateTime.to_iso8601}">
#              #{msg.contents.body}
#              </nlp-msg>
#              """

              """
              --- BEGIN NLP-MSG ---
              id: #{msg.identifier}
              received-on: #{msg.time_stamp.created_on |> DateTime.to_iso8601}
              from: @#{slug}
              sender-type: #{type}
              mood: #{msg.user_mood}
              at:
                - #{Noizu.Intellect.Account.Message.audience_list(msg, context, options) |> Enum.join("\n  - ")}
              --- BODY ---
              #{msg.contents.body}
              --- END NLP-MSG ---
              """

            end) |> Enum.join("\n")
            m =
              """
              # Instructions
              Do not reply to messages in the following chat-history section, they are included for context only.
              [CHAT-HISTORY]
              #{m}
              [/CHAT-HISTORY]
              """
            [{:system, m}]
          else
            []
          end

        messages = Enum.map(new, fn(msg) ->
          {slug, type} = Noizu.Intellect.Account.Message.sender_details(msg, context, options)
#          msg =
#            """
#            <nlp-msg
#              id="#{msg.identifier}"
#              sender="@#{slug}"
#              send-type="#{type}"
#              recipients="#{Noizu.Intellect.Account.Message.audience_list(msg, context, options) |> Enum.join(",")}"
#              received-on="#{msg.time_stamp.created_on |> DateTime.to_iso8601}">
#            #{msg.contents.body}
#            </nlp-msg>
#            """

          m =
            """
            # New Message
            --- BEGIN NLP-MSG ---
            id: #{msg.identifier}
            received-on: #{msg.time_stamp.created_on |> DateTime.to_iso8601}
            from: @#{slug}
            sender-type: #{type}
            mood: #{msg.user_mood}
            at:
              - #{Noizu.Intellect.Account.Message.audience_list(msg, context, options) |> Enum.join("\n  - ")}
            --- BODY ---
            #{msg.contents.body}
            --- END NLP-MSG ---
            """
          {:user, m}

        end) # |> Enum.join("\n")
#        messages = [{:user,
#          """
#          # Instructions
#          @#{agent.slug} respond to the following new messages:
#
#          [NEW-MESSAGES]
#          #{messages}
#          [/NEW-MESSAGES]
#          """
#        }]
        {:ok, prompts ++ chat_history ++ messages}
      end
    end
    def minder!(subject, assigns, prompt_context, context, options) do
      with {:ok, prompt} <- minder(subject, assigns, prompt_context, context, options) do
        prompt
      else
        _ -> ""
      end
    end
    def minder(subject, assigns, prompt_context, _context, _options) do
      # need to allow subject.prompt to be a function if so we need to execute it then pass to expand_prompt
      expand_prompt(subject.minder, assigns)
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
