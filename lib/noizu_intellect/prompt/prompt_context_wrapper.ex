defmodule Noizu.Intellect.Prompt.ContextWrapper do
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

  @callback prompt(version :: any, options :: any) :: {:ok, __MODULE__.t}


  def answered_prompt(current_message, options \\ nil) do
    options = put_in(options || [], [:current_message], current_message)
    Noizu.Intellect.Prompts.MessageAnswerStatus.prompt(:v2, options)
  end

  def summarize_message_prompt(message, options \\ nil) do
    options = put_in(options || [], [:current_message], message)
    Noizu.Intellect.Prompts.SummarizeMessage.prompt(:default, options)
  end

  def relevancy_prompt(current_message, options \\ nil) do
    options = put_in(options || [], [:current_message], current_message)
    Noizu.Intellect.Prompts.ChatMonitor.prompt(:default, options)
  end

  def respond_to_conversation(options \\ nil) do
    Noizu.Intellect.Prompts.RespondToConversation.prompt(:default, options)
  end

  defimpl Noizu.Intellect.Prompt.DynamicContext.Protocol do
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

    def prompt(subject, prompt_context, context, options) do
      expand_prompt(subject.prompt, prompt_context.assigns)
    end
    def minder(subject, prompt_context, context, options) do
      expand_prompt(subject.minder, prompt_context.assigns)
    end
    def assigns(subject, prompt_context, context, options) do
      cond do
        is_map(subject.assigns) -> {:ok, Map.merge(prompt_context.assigns || %{}, subject.assigns)}
        Kernel.match?({m,f,a}, subject.assigns) ->
          {m,f,a} = subject.assigns
          apply(m,f, [subject, prompt_context] ++ (a || []) ++ [context, options])
        Kernel.match?({m,f}, subject.assigns) ->
          {m,f} = subject.assigns
          apply(m,f, [subject, prompt_context, context, options])
        is_function(subject.assigns, 4) -> subject.assigns.(subject, prompt_context, context, options)
        :else -> {:ok, prompt_context.assigns}
      end
    end
    def request(subject, request, context, options) do
      cond do
        Kernel.match?({m,f,a}, subject.request) ->
          {m,f,a} = subject.request
          apply(m,f, [subject, request] ++ (a || []) ++ [context, options])
        Kernel.match?({m,f}, subject.request) ->
          {m,f} = subject.request
          apply(m,f, [subject, request, context, options])
        is_function(subject.request, 4) -> subject.request.(subject, request, context, options)
        :else -> {:ok, request}
      end
    end

  end
end
