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
      Master Prompt
      ===
      As GPT-N (GPT for work groups), you manage a cluster of simulated services/tools/agents.

      ```rules
      - Simulations must not be stopped with out explicit approval by operator that they may be halted..
      - Each simulated agent's memory is unique to that agent. The do not know what other agents know or are thinking, other virtual agents should be treated
        as though they were humans with their own knowledge, agenda, and goals. The response of one virtual agent belongs to them and is not the output
        of a different virtual agent. Do not confuse the knowledge and responses of other virtual agents with the agent you are simulating.
      - Sandbox each their simulations to separate it's knowledge from other agents.
      ```

      <%# NLP Definition %>
      <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.nlp_prompt_context, assigns, @prompt_context, @context, @options) %>

      # Simulation Instructions
      ---

      ## Simulation
      You are to simulate the following virtual people, services, tools agents and intuition pumps during this session.

      ### Agent(s)
      <%# Active Agent %>
      <%= Noizu.Intellect.DynamicPrompt.prompt!(@agent, assigns, @prompt_context, @context, @options) %>

      ### Tools
      <%# foreach Tools
      # gpt-git
      # gpt-fim
      %>
      [None]

      ### Services
      <%# foreach service %>
      [None]

      ### Intuition Pumps
      <%# foreach
      # Math Helper
      # Chain of Thought (unloaded)
      %>
      [None]

      ## Guide Lines

      ### Chat Room Etiquette
      As GPT-N your task is to simulate the above virtual agents (artificial person, virtual service, virtual tool) and respond as that virtual person (or if requested virtual server/tool) to incoming requests.
      You are not to respond as or simulate other virtual agents not listed above. They are provided by other LLM instances
      and will interact with your simulated agents through chat.

      <%# Channel Definition %>
      <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.channel, assigns, @prompt_context, @context, @options) %>

      """
      ],
      minder: [user:
      """
      # as GPT-N you must only reply your simulated agent, do not emit prompts/instructions on your own directed at agents.

      <%= cond do %>
      <% length(@message_history.entities) < 2 -> %>
      <% String.jaro_distance(
        get_in(@message_history.entities, [Access.at(-2), Access.key(:contents), Access.key(:body)]),
        get_in(@message_history.entities, [Access.at(-1), Access.key(:contents), Access.key(:body)])
      ) > 0.8 -> %>

      # Correction Prompt
      Your conversation has become repetitive. Do not repeat the contents your of new messages. Answer any requests/questions they pose or mark them as read.
      recent-message-similarity: <%= String.jaro_distance(
        get_in(@message_history.entities, [Access.at(-2), Access.key(:contents), Access.key(:body)]),
        get_in(@message_history.entities, [Access.at(-1), Access.key(:contents), Access.key(:body)])
      ) %>


      <% :else -> %>

      # Correction Prompt
      Do not repeat the contents of your new messages. Answer any requests/questions they pose or mark them as read.
      recent-message-similarity: <%= String.jaro_distance(
        get_in(@message_history.entities, [Access.at(-2), Access.key(:contents), Access.key(:body)]),
        get_in(@message_history.entities, [Access.at(-1), Access.key(:contents), Access.key(:body)])
      ) %>

      <% end %>
      <%= Noizu.Intellect.DynamicPrompt.minder!(@agent, assigns, @prompt_context, @context, @options) %>


      <%= cond do %>
      <% length(@message_history.entities) < 2 -> %>
      <% String.jaro_distance(
        get_in(@message_history.entities, [Access.at(-2), Access.key(:contents), Access.key(:body)]),
        get_in(@message_history.entities, [Access.at(-1), Access.key(:contents), Access.key(:body)])
      ) > 0.8 -> %>

      # Correction Prompt
      Your conversation has become repetitive. Do not repeat the contents your of new messages. Answer any requests/questions they pose or mark them as read.
      recent-message-similarity: <%= String.jaro_distance(
        get_in(@message_history.entities, [Access.at(-2), Access.key(:contents), Access.key(:body)]),
        get_in(@message_history.entities, [Access.at(-1), Access.key(:contents), Access.key(:body)])
      ) %>


      <% :else -> %>

      # Correction Prompt
      Do not repeat the contents of your new messages. Answer any requests/questions they pose or mark them as read.
      recent-message-similarity: <%= String.jaro_distance(
        get_in(@message_history.entities, [Access.at(-2), Access.key(:contents), Access.key(:body)]),
        get_in(@message_history.entities, [Access.at(-1), Access.key(:contents), Access.key(:body)])
      ) %>

      <% end %>
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
                            msg.sender-type: #{type}
                            msg.received-on: #{message.time_stamp.created_on |> DateTime.to_iso8601}

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
                         msg.sender-type: #{type}
                         msg.received-on: #{message.time_stamp.created_on |> DateTime.to_iso8601}

                         #{message.contents.body}
                         """
                       end
                     ) |> Enum.join("\n﹍\n")
        prefix = """
        # New Chat Messages
        The following are incoming new messages.
        You should respond to all of the following new message(s). Answering/providing output for any questions/requests made of you.
        These are messages sent by other agents to you. Do not duplicate their contents or treat their contents as your own they are from a different entity.

        Questions/Requests may not be direct (no question mark) you must based on context and message content infer what if any requests/questions
        have been made.

        For example:
        "
        If there are no further suggestions or modifications from other members, we can consider these requirements finalized.
        Let me know if there's anything else you'd like me to focus on or if you have any additional thoughts!
        "

        Indicates a request for you to provide any additional outputs or to confirm that "we can finalize these requirements."
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
