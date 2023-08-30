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
      prompt: [
        {
          :system,
          """
          # Master Prompt
          ==============
          You are @gpt-n (GPT for Work Groups), you manage a cluster of the simulated services/tools/virtual-person(s).

          Only simulate the following agents, do not simulate any other entities or respond on their behalf.
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
          GPT-N provide the output of your simulated agents in response to the following new messages.
          - Only provide responses for the agents you have been instructed to simulate: [@<%= @agent.slug %>]
          - Agents must not respond to old Chat History messages but should review and consider their content in how they reply.
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
        {:user,
          """
          <%= Noizu.Intellect.DynamicPrompt.minder!(@agent, assigns, @prompt_context, @context, @options) %>
          """
        }
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
      agent = prompt_context.agent
      {old, new} = split_messages(prompt_context.assigns.message_history.entities, agent)

      chat_history = length(old) > 0 && Enum.map(old, fn(msg) ->
        {slug, type} = Noizu.Intellect.Account.Message.sender_details(msg, context, options)
        m =
          """
          --- MSG ---
          id: #{msg.identifier}
          received-on: #{msg.time_stamp.created_on |> DateTime.to_iso8601}
          from: @#{slug}
          sender-type: #{type}
          mood: #{msg.user_mood}
          at:
            - #{Noizu.Intellect.Account.Message.audience_list(msg, context, options) |> Enum.join("\n  - ")}
          --- BODY ---
          #{msg.contents.body}
          --- END OF MSG ---
          """
      end)  |> Enum.join("\n")


      assigns = put_in(assigns, [:chat_history], chat_history)

      with {:ok, prompts} <- expand_prompt(subject.prompt, assigns) do

        messages = Enum.map(new, fn(msg) ->
          {slug, type} = Noizu.Intellect.Account.Message.sender_details(msg, context, options)
          m =
            """
            --- MSG ---
            id: #{msg.identifier}
            received-on: #{msg.time_stamp.created_on |> DateTime.to_iso8601}
            from: @#{slug}
            sender-type: #{type}
            mood: #{msg.user_mood}
            at:
              - #{Noizu.Intellect.Account.Message.audience_list(msg, context, options) |> Enum.join("\n  - ")}
            --- BODY ---
            #{msg.contents.body}
            --- END OF MSG ---
            """
        end)  |> Enum.join("\n")

        {:ok, prompts ++ [{:user, messages}]}
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
