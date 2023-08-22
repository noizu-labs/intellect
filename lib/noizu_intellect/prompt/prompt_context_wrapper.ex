defmodule Noizu.Intellect.Prompt.ContextWrapper do
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

  @callback prompt(version :: any, options :: any) :: {:ok, __MODULE__.t}
  @callback compile_prompt(any) :: any
  @callback compile_prompt(any, any) :: any
  @callback compile(any) :: any
  @callback compile(any, any) :: any

  def prompt_template(template, version, options \\ nil) do
    with x <- apply(template, :prompt, [version, options]),
         {:ok, x} <- apply(template, :compile, [x, options])
      do
      x
    end
  end

  def session_response_prompt(objectives, options \\ nil) do
    options = put_in(options || [], [:objectives], objectives)
    prompt_template(Noizu.Intellect.Prompts.SessionResponse, :default, options)
  end

  def answered_prompt(current_message, options \\ nil) do
    options = put_in(options || [], [:current_message], current_message)
    prompt_template(Noizu.Intellect.Prompts.MessageAnswerStatus, :default, options)
  end

  def summarize_message_prompt(message, options \\ nil) do
    options = put_in(options || [], [:current_message], message)
    prompt_template(Noizu.Intellect.Prompts.SummarizeMessage, :default, options)
  end

  def session_monitor_prompt(current_message, options \\ nil) do
    options = put_in(options || [], [:current_message], current_message)
    prompt_template(Noizu.Intellect.Prompts.SessionMonitor, :default, options)
  end

  def relevancy_prompt(current_message, options \\ nil) do
    options = put_in(options || [], [:current_message], current_message)
    prompt_template(Noizu.Intellect.Prompts.ChatMonitor, :default, options)
  end

  def respond_to_conversation(options \\ nil) do
    prompt_template(Noizu.Intellect.Prompts.RespondToConversation, :default, options)
  end

  def compile_prompt(expand_prompt, options \\ nil) do
    echo? = options[:verbose]
    case expand_prompt do
      prompt when is_bitstring(prompt) ->
        prompt = EEx.compile_string(prompt, trim: true)
        echo? && IO.puts "-----------------------------------------"
        echo? && IO.puts(prompt)
        {:ok, {:eex_prompt, {:user, prompt}}}
      {type, prompt} when is_bitstring(prompt) ->
        prompt = EEx.compile_string(prompt, trim: true)
        echo? && IO.puts "-----------------------------------------"
        echo? && IO.puts(prompt)
        {:ok, {:eex_prompt, {type, prompt}}}
      prompts when is_list(prompts) ->
        prompts = Enum.map(prompts,
          fn (prompt) ->
            case prompt do
              prompt when is_bitstring(prompt) ->
                prompt = EEx.compile_string(prompt, trim: true)
                echo? && IO.puts "-----------------------------------------"
                echo? && IO.puts(prompt)
                {:eex_prompt, {:user, prompt}}
              {type, prompt} when is_bitstring(prompt) ->
                prompt = EEx.compile_string(prompt, trim: true)
                echo? && IO.puts "-----------------------------------------"
                echo? && IO.puts(prompt)
                {:eex_prompt, {type, prompt}}
              _ -> nil
            end
          end
        )
        {:ok, prompts}
      nil -> {:ok, []}
      _ -> {:ok, []}
    end
  end

  def compile(this, options \\ nil) do
    this = %{this|
      compiled_prompt: compile_prompt(this.prompt, options),
      compiled_minder: compile_prompt(this.minder, options),
    }
    {:ok, this}
  end

  defimpl Inspect do
    def inspect(subject, _opts) do
      "#Prompt<#{subject.name}}>"
    end
  end

  defimpl Noizu.Intellect.DynamicPrompt do
    defp expand_prompt(expand_prompt, assigns, options \\ nil) do
      echo? = options[:verbose]
      case expand_prompt do
        {:eex_prompt, {type, compiled_prompt}} ->
          {prompt,_} = Code.eval_quoted(compiled_prompt, [assigns:  assigns])
          echo? && IO.puts "-----------------------------------------"
          echo? && IO.puts(prompt)
          {:ok, {type, prompt}}
        prompt when is_bitstring(prompt) ->
          {prompt,_} =  EEx.eval_string(prompt, [assigns:  assigns], trim: true)
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
                {:eex_prompt, {type, compiled_prompt}} ->
                  {prompt,_} = Code.eval_quoted(compiled_prompt, [assigns:  assigns])
                  echo? && IO.puts "-----------------------------------------"
                  echo? && IO.puts(prompt)
                  {type, prompt}
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
    def prompt(subject, assigns, prompt_context, _context, _options) do
      # need to allow subject.prompt to be a function if so we need to execute it then pass to expand_prompt
      expand_prompt(subject.prompt, assigns)
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
