defmodule Noizu.Intellect.Prompts.SessionResponse do
  @behaviour Noizu.Intellect.Prompt.ContextWrapper
  require Logger

  @vsn 1.0
  defstruct [
    prompt: nil,
    minder: nil,
    settings: nil,
    assigns: nil,
    request: nil,
    arguments: nil,
    vsn: @vsn
  ]


  @type t :: %__MODULE__{
               prompt: any,
               minder: any,
               settings: any,
               assigns: any,
               request: any,
               arguments: any,
               vsn: any
             }

  def assigns(_subject, prompt_context, _context, _options) do
    #{:ok, graph} = Noizu.Intellect.Account.Message.Graph.to_graph(prompt_context.message_history, prompt_context.channel_members, context, options)
    assigns = prompt_context.assigns
              |> Map.merge(
                   %{
                     nlp: true,
                     members: Map.merge(prompt_context.assigns[:members] || %{}, %{verbose: :detailed})
                   })
    {:ok, assigns}
  end

  def prompt(version, options \\ nil)
  def prompt(:default, options), do: prompt(:v1, options)
  def prompt(:v1, options) do
    current_message = options[:current_message]

    %Noizu.Intellect.Prompts.SessionResponse{
      assigns: &__MODULE__.assigns/4,
      arguments: %{current_message: current_message},
      prompt: [user:
      """
      Master Prompt
      ===
      As GPT-N (GPT for work groups), you manage a cluster of simulated services/tools/agents.

      ```rules
      - Simulations must not be stopped with out explicit approval by operator that they may be halted..
      ```

      <%# NLP Definition %>
      <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.nlp_prompt_context, @prompt_context, @context, @options) %>

      # Simulation Instructions
      ---

      ## Simulation
      You are to simulate the following virtual people, services, tools agents and intuition pumps during this session.

      ### Agent(s)
      <%# Active Agent %>
      <%= Noizu.Intellect.DynamicPrompt.prompt!(@agent, @prompt_context, @context, @options) %>

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
      <%= Noizu.Intellect.DynamicPrompt.prompt!(@prompt_context.channel, @prompt_context, @context, @options) %>

      # Chat History
      """
      ],
      minder: [user:
      """
      <%= Noizu.Intellect.DynamicPrompt.minder!(@agent, @prompt_context, @context, @options) %>
      """
      ],
    }
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
    def prompt!(subject, prompt_context, context, options) do
      with {:ok, prompt} <- prompt(subject, prompt_context, context, options) do
        prompt
      else
        _ -> ""
      end
    end
    def prompt(subject, prompt_context, context, options) do
      with {:ok, prompts} <- expand_prompt(subject.prompt, prompt_context.assigns) do
        {processed, indirect, new} = prompt_context.assigns.message_history.entities
                                     |> split_messages(prompt_context.agent)
        messages = (processed ++ indirect)
                   |> Enum.map(
                        fn(message) ->
                          {slug, type} = Noizu.Intellect.Account.Message.sender_details(message, context, options)
                            """
                            msg: #{message.identifier}
                            sender: @#{slug}
                            sender-type: #{type}
                            received-on: #{message.time_stamp.created_on |> DateTime.to_iso8601}

                            #{message.contents.body}
                            """
                        end
                      ) |> Enum.join("\n﹍\n")
        messages = [{:system, messages}]
        new = new |> Enum.map(
                       fn(message) ->
                         {slug, type} = Noizu.Intellect.Account.Message.sender_details(message, context, options)
                         """
                         msg: #{message.identifier}
                         sender: @#{slug}
                         sender-type: #{type}
                         received-on: #{message.time_stamp.created_on |> DateTime.to_iso8601}

                         #{message.contents.body}
                         """
                       end
                     ) |> Enum.join("\n﹍\n")
        new = [{:user, new}]
        {:ok, prompts ++ messages ++ new}
      end
    end
    def minder!(subject, prompt_context, context, options) do
      with {:ok, prompt} <- minder(subject, prompt_context, context, options) do
        prompt
      else
        _ -> ""
      end
    end
    def minder(subject, prompt_context, _context, _options) do
      # need to allow subject.prompt to be a function if so we need to execute it then pass to expand_prompt
      expand_prompt(subject.minder, prompt_context.assigns)
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
