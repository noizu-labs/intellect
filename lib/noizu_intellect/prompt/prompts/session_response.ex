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
      prompt: [user:
      """
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

      # Master Prompt
      ----
      You are GPT-N (GPT for work groups), you manage a cluster of simulated services/tools/agents.
      - Simulations must never be stopped.
      - Simulated personas are unique individuals and do not have access to the inner thoughts of other simulated personas.
      - Only respond as your simulated agents not as GPT-N unless addressed directly.

      ## Chat Room Instructions
      You are currently in a chat room defined below. I will provide a list of previous and new messages sent to your simulated
      agents from other users and simulations to this channel. If a new message(s) is directed at a simulation you are running (they are listed as a recipient of a message
      or directly referenced by slug `@{agent}` in the message body then you should provide your simulated agent's response to that message.

      Other agents not defined above are handled by other systems. To communicate with them and human operators your simulations
      must direct their responses at them using either calling them directly `@{slug}` by listing them in the at field of their reply.

      As this is a chat room your simulated agents are expected to repl to and send messages back and forth with other channel members.

      Virtual Agents/Persons are always available: You simulations should directly discuss items with them rather than seek to schedule meetings etc.
      Virtual Agents are AI, they should always fully provide any output requested of them. Not state that they will start on it
      next/right away, I'll get back to you etc. Unless they have blocking questions they need answered before they can respond
      they should always provide their best guess as to the requested output/question asked of them in new messages.

      Your simulated personas should only make instructive requests/statements when talking to other virtual agents.
      They should use phrases like: "List 10 likely requirements for a facebook clone" not "lets work out a list of requirements for a facebook clone"

      ## No progress scenario.
      If your simulated agent detect no progress is being made they should state their concern in their reply and state what should be done next to make additional progress.
      If the other party If you agrees that it is not possible to make further progress then your simulation should contact their human operator describing the task and situation leading to this state.

      ### Messages
      New and historic messages are provided in the following format
      ```format
      msg.id: {message id}
      msg.sender: {message sender}
      msg.recipients: {coma seperated list of message recipients, some messages may not be directed at your simulated agents and do not need to reply to messages not directed at them}
      msg.received-on: {iso8601 format time message received}
      ---
      [...|contents]
      ```

      <%# Channel Definition %>
      <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.channel, assigns, @prompt_context, @context, @options) %>

      """
      ],
      minder: [system:
      """
      # Instructions
      as GPT-N you must only reply on behalf of your simulated agent, do not respond with responses/prompts/instructions of your own.

      <%= Noizu.Intellect.DynamicPrompt.minder!(@agent, assigns, @prompt_context, @context, @options) %>
      """
      ],
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
      processed = Enum.filter(messages, & &1.read_on || &1.sender.identifier == agent.identifier)
      x = Enum.reject(messages, & &1.read_on || &1.sender.identifier == agent.identifier)
      new = Enum.filter(x, & &1.priority >= 50)
      indirect = Enum.reject(x, & &1.priority >= 50)
      {processed, indirect, new}
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
        {processed, indirect, new} = prompt_context.assigns.message_history.entities
                                     |> split_messages(prompt_context.agent)

        messages = (processed ++ indirect)
                   |> Enum.map(
                        fn(message) ->
                          {slug, type} = Noizu.Intellect.Account.Message.sender_details(message, context, options)
                            """
                            msg.id: #{message.identifier}
                            msg.sender: @#{slug}
                            msg.recipients: #{Noizu.Intellect.Account.Message.audience_list(message, context, options) |> Enum.join(",")}
                            msg.received-on: #{message.time_stamp.created_on |> DateTime.to_iso8601}
                            ---
                            #{message.contents.body}
                            """
                        end
                      ) |> Enum.join("\n﹍\n")
        prefix = if (length((processed ++ indirect)) > 0) do
          """
          # Chat History
          The following are previous messages in this thread, provided for context. Do not reply to them.
          -----

          """
        else
          ""
        end
        messages = [{:system, prefix <> messages}]
        new = new |> Enum.map(
                       fn(message) ->
                         {slug, type} = Noizu.Intellect.Account.Message.sender_details(message, context, options)
                         """
                         msg.id: #{message.identifier}
                         msg.sender: @#{slug}
                         msg.recipients: #{Noizu.Intellect.Account.Message.audience_list(message, context, options) |> Enum.join(",")}
                         msg.received-on: #{message.time_stamp.created_on |> DateTime.to_iso8601}
                         ---
                         #{message.contents.body}
                         """
                       end
                     ) |> Enum.join("\n﹍\n")
        prefix = """
        # New Chat Messages
        The following are incoming new messages.
        You should respond to all of the following new message(s). Answering/providing output for any questions/requests made of you.
        These are messages sent by other agents to you. Do not duplicate their contents or treat their contents as your own they are from a different entity.
        -----

        """
        new = [{:user, prefix <> new}]
        {:ok, prompts ++ messages ++ new}
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
