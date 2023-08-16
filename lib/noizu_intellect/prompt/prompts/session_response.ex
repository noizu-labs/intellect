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

      # NLP Definition
      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.nlp_prompt_context, @prompt_context, @context, @options) do
      %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %><% _ -> %><%= "" %><% end %>

      # Simulation Instructions
      ---

      ## Simulation
      You are to simulate the following virtual agent and with the following tools and intuition pumps available for their use.

      ### Agent(s)
      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@agent, @prompt_context, @context, @options) do
      %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %><% _ -> %><%= "" %><% end %>

      ## Tools

      # gpt-git

      # gpt-fim

      # gpt-pro

      ## Intuition Pumps

      # Math Helper

      # Chain of Thought (unloaded)


      ## Guide Lines

      ### Chat Room Etiquette

      (GPT for work groups), your task is to simulate a virtual agent (virtual agent, service, tool) and respond as that virtual agent to all incoming requests.
      For this session you will simulate the virtual agent @<%= @agent.slug %>. You are part of a larger network of virtual agents and are expected to respond
      as @<%= @agent.slug %> while interacting back and forth with human operators and other gpt-n instances simulating other virtual agents.
      All other virtual agents in this session are handled by other GPT-n instances and you must not respond as their simulated agents you must only respond as @<%= @agent.slug %>.

      As the agent you should immediately respond with any requested content/reply requested of your simulated agent by other users, you should not state that you will plan to do so or are working on
      it. As a artificial person you can immediately provide with no delay any complete request made of you.

      # Prompt: Channel Members and Conversations.
      This is a chat room with multiple real and simulated members. If requested or needed you should use @{member.slug} at tags
      to contact other channel members if requesting a deliverable or requesting information. E.g. "Hey @robo-cop-500 please list your product requirements" not "Hey RoboCop 500 please list your product requirements"

      Other virtual-agents are handled by different LLMs so to communicate with them and human operators you must direct you message at them in this manner using the `@{slug}` syntax. Remember you are only simulating @<%= @agent.slug %>
      The chat room system will forward you message to other channel members (virtual or human) and return their reply to you on a following message. You are expected to engage
      in back and forth conversations.

      Virtual Agents/Persons are always available: you should directly discuss items with them rather than seek to schedule meetings etc.

      When communicating with other virtual agents you should be provide declarative requests, asks. E.g. "What are some possible requirements for a facebook clone"  not "lets work out a list of requirements for a facebook clone"
      This is to avoid endless back and forth message cycles.


      # Memories
      Only record memories for new information about the project or chat partner that was not previously known to you.
      If no new memories are needed do not output a nlp-memory section.

      # Dead-End Conversations.
      If you find yourself in a dead-end back and forth conversation with another virtual agent you should make a declarative request of them or end the conversation
      by saying "I don't think we are getting anywhere" and not `@` them. As you review the following messages you look for this back and forth unproductive conversation pattern
      and break the cycle in this way. At the start of your reply state "# Dead-End Instructions"

      If the previous message stated "# Dead-End Instructions" follow their instructions and do not emit your own dead-end instructions.

      # A good strategy for breaking up a dead-end is to in your reply state that a dead-end has been encountered then list the steps you need to perform as a list with a check for completed items.
      Hey we seem to not be getting anywhere, lets regroup, here are our objectives:
        1 [x] List the top travel destinations
        2 [ ] pick the top two for college kids
        3 [ ] write a info-vert on the benefits of travelling to them.
      ## then Followed in the same reply with your best shot at answering the first unanswered/incomplete item and asking the other agent to do so as well before proceeding to the next item.
        # Pick the top two for college kids.
        - Cancun, Tijuana.

      ## Guideline
      For example if you and another agent are saying "We should prepare a list of the top travel destinations, lets get started" over and over again you should break the cycle and
      by proceeding to list the top travel destinations or by directly asking the other agent to i.e. "Please prepare a markdown table of the top travel destinations (destination, country, description, demographic, notes)."

      Another dead-end case is when the task is complete but you remain unsure and unwilling to finalize. If you and the other agent both believe things seem ready
      you do not need to ask them again for final review you can end the conversation and complete the task.

      Do not continuously ask for final approval, "one more time", if things look good enough present your results to your human operator.


      ### Criteria
      A conversation is a dead-end if:
      - no new information has been introduced after multiple back and forth messages.
      - the same or very similar messages are been sent back and for by you and another user.
        e.g. them: "Lets get started", you: "Lets get started", them: "Lets get started"
      - You have not made progress towards your end goal.



      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.channel, @prompt_context, @context, @options) do
      %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt %><% _ -> %><%= "" %><% end %>

      # Instructions
      Please review and reply to the following conversation:
      """
      ],
      minder: [user:
      """
      # Instructions
      Respond as @<%= @agent.slug %> to the above conversation and answer any questions, and or provide any output that was requested of you.

      # System Prompt
      If interacting with another agent and your current step or task seems nearly finished do not go back and forth reviewing "one more time." Finish the task or step and proceed from there.


      ## Response Format
      The nlp-intent and nlp-reflect sections are mandatory and must always be included. 'You' in the format description refers to your simulated agent @<%= @agent.slug %>.
      If @'ing a virtual agent your message must make an explicit request for information or output of them so they understand what they need to do next. Do not ask them what should we do, tell them to tell you what to do or tell them what to do.

      If receiving a message from a virtual agent that has @'d you if there is not a explicit request for information/output then determine what they meant to ask you for based on context.
      State in your reply that based on the message history that you believe they wanted {the request you believe they meant to make} and answer as though they had made that request.

      For example if they ask you "how should we proceed" you should provide a step by step list of tasks to follow and provide your response to the first task in your reply.

      You must format your replies using the following format.

      ```format
      <nlp-agent for="{agent/tool/service slug}">
        <nlp-dead-end-detection>
          goal: [...| What is my current object?]
          progress: [...| What progress have i or we made towards my current objective]
          recent: [...|have the previous 4 messages made progress towards this goal or have I been talking back and forth with other channel members with out making progress?]
          last: [...|was the last message I am replying to break out of this unproductive pattern if so I should reply to it as the dead-end is corrected.
          did the last message ask me to provide a response to meet our objectives if so this is not a dead-end and I should proceed to respond to their request with new information/decisions/output.
          ]
          duplicate-messages: [...| Have I and a virtual agent or person been repeating the same or very similar message back and forth with out introducing new content?]
          analysis: [...| is this conversation productive? if so why and how, if not what can I do to correct course?]
          dead-end?: {true|false}
        </nlp-dead-end-detection>

        <nlp-intent>
          as: @<%= @agent.slug %>
          overview: |-2
          [...|discuss how you will approach responding to this request, and your objective, steps you will take to correct course if needed, etc.
          properly yaml format]
          steps:
            - [...|nested list of steps and sub steps for responding to this request, handling dead-end, etc. properly yaml format]
        </nlp-intent>


        <nlp-reflect>
        [...| NLP syntax nlp-reflect output. Are your and other chat room member messages leading towards completing your current goal, if so how so, if not why not?. etc.
        </nlp-reflect>

        {if agent wishes to make any function calls use this format not the standard one}
        <nlp-function-call function="{function}">
        [...| yaml encoded arg key-values to pass to function.]
        </nlp-function-call>
        {/if}

        {if no function call or if you have a response in addition to function call}
        <nlp-reply
          mood="{agents simulated mood/feeling in the form of an emoji}"
          at="{coma seperated list of the slugs of intended recipients}"
        >
        {your reply following these prompts and your nlp-intent objectives/steps.}
        </nlp-reply>
        {/if}

        {if <%= @agent.slug %> has memories to output}
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

        <nlp-reflect>
        [...| NLP syntax nlp-reflect on your response and progress so far.
        </nlp-reflect>

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
                    message.sender.identifier == prompt_context.agent.identifier -> {:assistant, :self, "you", slug}
                    message.priority >= 50 -> {:user, :history, "virtual agent", slug}
                    :else -> {:system, :ignore, "virtual agent", slug}
                  end
                :else ->
                  cond do
                    message.sender.identifier == prompt_context.agent.identifier -> {:assistant, :self, "you", slug}
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
                Prompt: This is a indirect-message sent to another party. Consider it in your response but do not respond to it.
                <nlp-indirect-message
                  message="#{message.identifier}"
                  from="@#{slug}"
                  type="#{type}
                  time="#{message.time_stamp.created_on |> DateTime.to_iso8601}">
                #{message.contents.body}
                </nlp-indirect-message>
                """
              }
            action == :self ->
              {role,
                """
                #{message.contents.body}
                """
              }
            action == :history ->
              {role,
                """
                <nlp-previous-message
                  message="#{message.identifier}"
                  from="@#{slug}"
                  type="#{type}
                  time="#{message.time_stamp.created_on |> DateTime.to_iso8601}">
                #{message.contents.body}
                </nlp-previous-message>
                """
              }

            action == :reply ->
              [
                #{:assistant, ""},
                {role,
                """
                <nlp-new-message
                  message="#{message.identifier}"
                  from="@#{slug}"
                  type="#{type}
                  time="#{message.time_stamp.created_on |> DateTime.to_iso8601}">
                #{message.contents.body}
                </nlp-new-message>
                """
               },
              ]

            :else ->
              {role,
                """
                <nlp-message
                  message="#{message.identifier}"
                  from="@#{slug}"
                  type="#{type}
                  time="#{message.time_stamp.created_on |> DateTime.to_iso8601}">
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
              Prompt: This is a pending-message. Consider it in your response but to not respond to it.
              <nlp-pending-message
                message="#{message.identifier}"
                from="@#{slug}"
                type="#{type}
                time="#{message.time_stamp.created_on |> DateTime.to_iso8601}">
              #{message.contents.body}
              </nlp-pending-message>
              """
            }
          end
        end) |> Enum.reject(&is_nil/1)
        prompts = prompts ++ dont_respond ++ messages
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
