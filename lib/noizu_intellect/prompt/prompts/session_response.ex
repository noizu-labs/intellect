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

      # Instructions
      Below are recent and relevant messages from your current channel's chat history. Your simulated agent should review and
      and respond as instructed.
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
    def prompt(subject, prompt_context, _context, _options) do
      # need to allow subject.prompt to be a function if so we need to execute it then pass to expand_prompt
      with {:ok, prompts} <- expand_prompt(subject.prompt, prompt_context.assigns) do
        # @todo logic to filter/pick briefs.

        # walk backwards until we find a message where our priority > 60 indicating an at message.
        # Then split the map and put the non at messages in a special system prompt to avoid the agent responding to them.
        messages = prompt_context.assigns.message_history.entities
        r = Enum.reverse(messages)
            |> Enum.find_value(& &1.priority >= 50 && &1.identifier || nil)
        {messages, pending} = if r do
          index = Enum.find_index(messages, & &1.identifier == r)
          Enum.split(messages, index + 1)
        else
          {[], messages}
        end

        messages = Enum.map(messages, fn(message) ->
          {role, action, type, slug} = case message.sender do
            %Noizu.Intellect.Account.Member{user: user} ->
              cond do
                message.read_on ->
                  {:user, :history, "human operator", user.slug}
                :else ->
                  {:user, :reply, "human operator", user.slug}
              end
            %Noizu.Intellect.Account.Agent{slug: slug, details: %{title: name}} ->
              cond do
                message.read_on ->
                  cond do
                    message.sender.identifier == prompt_context.agent.identifier -> {:assistant, :self, "virtual agent", slug}
                    message.priority >= 50 -> {:user, :history, "virtual agent", slug}
                    :else -> {:system, :ignore, "virtual agent", slug}
                  end
                :else ->
                  cond do
                    message.sender.identifier == prompt_context.agent.identifier -> {:assistant, :self, "virtual agent", slug}
                    message.priority >= 50 -> {:user, :reply, "virtual agent", slug}
                    :else -> {:system, :ignore, "virtual agent", slug}
                  end
              end
            # Support for Services/Tools
            _ -> {nil, nil, nil, nil}
          end
          cond do
            is_nil(role) -> nil
            action == :ignore ->
              {role,
                """
                This is a indirect-message sent to another party. Consider it in your response but do not respond to it.
                ------
                <nlp-message status="ignore" msg-id="#{message.identifier}" sender="@#{slug}" sender-type="#{type}" sent-on="#{message.time_stamp.created_on |> DateTime.to_iso8601}">
                #{message.contents.body}
                </nlp-message>
                """
              }
            action == :self ->
              {role,
                """
                <nlp-message status="old" msg-id="#{message.identifier}" sender="@#{slug}" sender-type="#{type}" sent-on="#{message.time_stamp.created_on |> DateTime.to_iso8601}">
                #{message.contents.body}
                </nlp-message>
                """
              }
            action == :history ->
              {role,
                """
                <nlp-message status="old" msg-id="#{message.identifier}" sender="@#{slug}" sender-type="#{type}" sent-on="#{message.time_stamp.created_on |> DateTime.to_iso8601}">
                #{message.contents.body}
                </nlp-message>
                """
              }

            action == :reply ->
              [
                #{:assistant, ""},
                {role,
                """
                <nlp-message status="new" msg-id="#{message.identifier}" sender="@#{slug}" sender-type="#{type}" sent-on="#{message.time_stamp.created_on |> DateTime.to_iso8601}">
                @#{prompt_context.agent.slug}

                #{message.contents.body}
                </nlp-message>
                """
               },
              ]

            :else ->
              {role,
                """
                <nlp-message status="ignore" msg-id="#{message.identifier}" sender="@#{slug}" sender-type="#{type}" sent-on="#{message.time_stamp.created_on |> DateTime.to_iso8601}">
                #{message.contents.body}
                </nlp-message>
                """
              }
          end
        end) |> Enum.reject(&is_nil/1) |> List.flatten()

        dont_respond = Enum.map(pending, fn(message) ->
          {role, action, type, slug} = case message.sender do
            %Noizu.Intellect.Account.Member{user: user} -> {:system, :ignore, "human operator", user.slug}
            %Noizu.Intellect.Account.Agent{slug: slug, details: %{title: name}} ->
              role = :system
              {role, :ignore, "virtual agent", slug}
            # Support for Services/Tools
            _ -> {nil, nil, nil, nil}
          end
          if role do
            {role,
              """
              This is a pending-message. Consider it in your response but to not respond to it.
              ----
              <nlp-message status="ignore" msg-id="#{message.identifier}" sender="@#{slug}" sender-type="#{type}" sent-on="#{message.time_stamp.created_on |> DateTime.to_iso8601}">
              #{message.contents.body}
              </nlp-message>
              """
            }
          end
        end) |> Enum.reject(&is_nil/1)
        prompts = prompts ++ dont_respond ++ messages
        Enum.map(prompts,
          fn({type, body}) ->
          IO.puts("[#{prompt_context.agent.slug}] #{type}\n#{body}\n---------------------\n\n\n")
          end)
        {:ok, prompts}
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
