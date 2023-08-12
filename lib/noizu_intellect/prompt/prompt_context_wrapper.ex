defmodule Noizu.Intellect.Prompt.ContextWrapper do
  @vsn 1.0
  defstruct [
    prompt: nil,
    minder: nil,
    settings: nil,
    assigns: nil,
    vsn: @vsn
  ]


  @type t :: %__MODULE__{
               prompt: any,
               minder: any,
               settings: any,
               vsn: any
             }

  @callback prompt(version :: any, options :: any) :: {:ok, __MODULE__.t}


  def answered_prompt(current_message, options \\ nil) do
    options = put_in(options || [], [:current_message], current_message)
    Noizu.Intellect.Prompts.MessageAnswerStatus.prompt(:v2, options)
  end

  def summarize_message_prompt() do
    %__MODULE__{
    prompt: [system: """
    # Instruction Prompt
    For every user provided message output a summary of it's contents and only a summary of it's contents. Do not output any comments
    before or after the summary of the message contents. The summary should be around 1/3rd of the original message size but can be longer if important details are lost.
    Code snippets should be reduced by replacing method bodies, etc with ellipse ("Code Here ...") comments.

    """,
    user: """
    <%= for message <- @prompt_context.message_history do %>
    <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(message, @prompt_context, @context, @options) do %>
    <% {:ok, prompt} when is_bitstring(prompt)  -> %>
    <%= String.trim_trailing(prompt) %><% _ -> %><%= "" %>
    <% end  # end case %>
    <% end  # end for %>
    """
    ],
    settings: fn(request, prompt_context, context, options) ->
      chars = Enum.map(request.messages, fn(message) ->
        String.length(message.body)
      end) |> Enum.sum()
      approx_tokens = div(chars,3)

      request = cond do
        approx_tokens < 2048 ->
          request
          |> put_in([Access.key(:model)], "gpt-3.5-turbo")
          |> put_in([Access.key(:model_settings), :max_tokens], 2048)
        :else -> put_in(request, [Access.key(:model)], "gpt-3.5-turbo-16k")
      end
      |> put_in([Access.key(:model_settings), :temperature], 0.2)
      {:ok, request} |> IO.inspect(label: "MODIFIED REQUEST SETTINGS")
    end
    }
  end

  def relevancy_prompt(current_message, options \\ nil) do
    options = put_in(options || [], [:current_message], current_message)
    Noizu.Intellect.Prompts.ChatMonitor.prompt(:v2, options)
  end

  def respond_to_conversation(options \\ nil) do
    Noizu.Intellect.Prompts.RespondToConversation.prompt(:v1, options)
  end

  defimpl Noizu.Intellect.Prompt.DynamicContext.Protocol do
    def prompt(subject, prompt_context, context, options) do
      echo? = false
      with {:ok, assigns} <- Noizu.Intellect.Prompt.DynamicContext.assigns(prompt_context, context, options) do
        case subject.prompt do
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
          _ -> nil
        end
      end
    end
    def minder(subject, prompt_context, context, options) do
      echo? = false
      with {:ok, assigns} <- Noizu.Intellect.Prompt.DynamicContext.assigns(prompt_context, context, options) do
        case subject.minder do
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
          _ -> nil
        end
      end
    end
  end
end
