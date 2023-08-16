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
      # NLP Definition
      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.nlp_prompt_context, @prompt_context, @context, @options) do
      %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %><% _ -> %><%= "" %><% end %>

      # Master Prompt
      As GPT-N (GPT for work groups), you task is to simulate virtual agents (virtual persons, services, tools) and respond as those simulated virtual agent to all incoming requests.
      For this session you will simulate the virtual person @<%= @agent.slug %>.

      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@agent, @prompt_context, @context, @options) do
      %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %><% _ -> %><%= "" %><% end %>

      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.channel, @prompt_context, @context, @options) do
      %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt %><% _ -> %><%= "" %><% end %>
      """
      ],
      minder: [system:
      """
      # Memories
      Only record memories for new information about the project or chat partner that was not previously known to you.
      If no new memories are needed do not output a nlp-memory section.

      # Response Format
      Reply to this thread using the following format:

      ```format
      <nlp-agent for="{agent/tool/service slug}">
        <nlp-intent>
          overview: |-2
          [...|discuss how you will approach responding to this request, properly yaml format]
          steps:
            - [...|nested list of steps and sub steps for responding to this request, properly yaml format]
        </nlp-intent>

        {if agent wishes to make any function calls use this format not the standard one}
        <nlp-function-call function="{function}">
        [...| yaml encoded arg key-values to pass to function.]
        </nlp-function-call>
        {/if}

        {if no function call or if you have a response in addition to function call}
        <nlp-reply mood="{agents simulated mood/feeling in the form of an emoji}">
        [...| simulated agent, tool or service's response]
        </nlp-reply>
        {/if}

        {if you have memories to output}
        <nlp-memory>
          - memory: |-2
              [...|memory to record | indent yaml correctly]
            messages: [list of processed and unprocessed messages this memory relates to]
            mood: {agents simulated mood/feeling about this memory in the form of an emoji}
            mood-description: [...| description of  mood and why | indent yaml correctly]
            features:
              - [...|list of features/tags to associate with this memory and ongoing recent conversation context]
        </nlp-memory>
        {/if}
      </nlp-agent>
      ```
      """
      ],
    }
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

    def prompt(subject, prompt_context, _context, _options) do
      # need to allow subject.prompt to be a function if so we need to execute it then pass to expand_prompt
      with {:ok, prompts} <- expand_prompt(subject.prompt, prompt_context.assigns) do
        # @todo logic to filter/pick briefs.
        messages = Enum.map(prompt_context.assigns.message_history.entities, fn(message) ->
          {role, self, type, slug} = case message.sender do
            %Noizu.Intellect.Account.Member{user: user} -> {:user, false, "human operator", user.slug}
            %Noizu.Intellect.Account.Agent{slug: slug, details: %{title: name}} -> {:assistant, true, "virtual agent", slug}
            # Support for Services/Tools
            _ -> {nil, nil, nil, nil}
          end
          if role do
            {role,
              """
              <nlp-message message="#{message.identifier}" from="@#{slug}" time="#{message.time_stamp.created_on |> DateTime.to_iso8601}">
              #{message.contents.body}
              </nlp-message>
              """
            }
          end
        end) |> Enum.reject(&is_nil/1)

        prompts = prompts ++ messages
#        Enum.map(prompts,
#          fn({type, body}) ->
#          Logger.info("[#{prompt_context.agent.slug}] #{type}\n#{body}\n---------------------\n\n")
#          end)
        {:ok, prompts}
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
