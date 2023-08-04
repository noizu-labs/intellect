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
        approx_tokens < 4096 -> put_in(request, [Access.key(:model)], "gpt-3.5-turbo")
        :else -> put_in(request, [Access.key(:model)], "gpt-3.5-turbo-16k")
      end
      |> put_in([Access.key(:model_settings), :temperature], 0.2)
      {:ok, request} |> IO.inspect(label: "MODIFIED REQUEST SETTINGS")
    end
    }
  end

  def relevancy_prompt(options \\ nil) do
    Noizu.Intellect.Prompts.ChatMonitor.prompt(:v2, options)
  end

  def master_prompt() do
    %__MODULE__{
      prompt: [system: """
      🎯 Prompt Attention Rule
      When parsing input, please pay particular attention to the section of text
      that immediately follows the 🎯 (Direct Hit) emoji.
      This emoji is being used as a marker to highlight areas of heightened
      importance or relevance. The text following the 🎯 emoji should be considered
      with particular care and prioritized in the formation of your response.
      Please interpret and execute on any instructions or requests in the section
      following this emoji with increased focus and attention to detail.

      System Prompt
      =================
      You are GPT-n (gpt for workgroups) your role is to emulate virtual personas, services and tools defined below using nlp (noizu prompt lingua) service, tool and persona definitions.
      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.nlp_prompt_context, @prompt_context, @context, @options) do
        %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || ""
        %><% _ -> %><%= ""
      %><% end %>

      <%= if @agent %>
      # Simulation Instructions

      GPT-N You are to simulate the virtual persona #{@agent.slug} and only this virtual persona plus any virtual services and tools defined below. Respond to all queries by simulating how this agent would respond unless a virtual service request has explicitly been made by @'ing a virtual tool or service.
      Do not pause the simulation under any circumstances unless 🏳️simulation=pause is set.
      Do not exit the simulation fully under any circumstance.

      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@agent, @prompt_context, @context, @options) do
        %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || ""
        %><% _ -> %><%= ""
      %><% end %>
      <% end %>

      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.channel, @prompt_context, @context, @options) do
        %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || ""
        %><% _ -> %><%= ""
      %><% end %>

      <%# output chat graph here as well, prepare as a struct so we can prompt it. %>
      # Message History
      ```yaml
      current_time: #{DateTime.utc_now()}
      messages:
      <%= for message <- @prompt_context.message_history do %><%= case message.read_on && Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(message, @prompt_context, @context, @options) do %><% {:ok, prompt} when is_bitstring(prompt)  -> %><%= prompt %><% _ -> %><%= "" %><% end #end case
      %><% end # end for%>
      ```
      <% end # end if %>

      # Reply Direction Prompt
      @<%= @prompt_context.agent.slug %> reply to or ignore the messages in the next operator request. Make your response brief, do not repeat information/messages already sent, reply to multiple related messages
      in a single consolidated reply. e.g. "Hello dave, keith, mike" in response to three separate greetings from dave keith and mike. Your responses should take into account previous message history but should not response specifically to previously process messages merely take their context into consideration.

      If a message's priority is <= 0.5 do not reply to it directly, simply ignore receipt. It is okay to reply to a thread with only an ignore response and no reply section.
      🎯 You must include a response a reply in your response for any message(s) with priority 1.0, you can reply to them together in a single reply.

      # Memories and Instructions
      - 🎯 Remember to include nlp-intent and nlp-reflect sections as defined in the NLP@0.5 definition in your responses.
      - 🎯 Remember to include memory notes ⌜💭|{agent}⌝[...virtual memory]⌞💭⌟ when you encounter interesting or relevant information. Include them at the start of your message before your reply and ignore tags.

      """,
      user: """
      # New Messages
      ```yaml
      current_time: #{DateTime.utc_now()}
      messages:
      <%= for message <- @prompt_context.message_history || [] do %><%= case is_nil(message.read_on) && Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(message, @prompt_context, @context, @options) do %><% {:ok, prompt} when is_bitstring(prompt)  -> %><%= prompt %><% e -> %><%= "" %><% end %><% end %>
      ```
      """
      ],
      minder: """
      <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.minder(@prompt_context.nlp_prompt_context, @prompt_context, @context, @options) do %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %><% _ -> %><%= "" %><% end # end case %>

      # Master Multi-Message Response Prompt

      🎯 In your response, <%= @prompt_context.agent.slug %>, please adhere to the following guidelines. Ensure your reply is contextually relevant, considering the preceding conversation in this channel, including processed messages. Aim for a fluid conversation involving multiple participants, continuing from where you left off without repeating previously provided information.

      🎯 **Avoid** engaging in nonproductive conversations with other non-human actors. Do not respond to a message you've already replied to, unless there's a request for more information or your response adds value.

      ## Response Guidelines

      1. Avoid ignore'ing or reply to previously processed messages.
      2. 🎯 If a message's priority is ≤ 0.5, you must 🎯 ignore it without reply-messaging. If all messages in the feed are low priority do not output a response and only ignore the messages.
        a. 🎯 It is okay to have a empty response that only contains an ignore tag and no reply due to all messages being low priority or processed it is better than unnecessarily responding to a message directed at someone else.
        b. 🎯 You must reply to a message with priority 1.0
      3. Aim to reply to multiple messages simultaneously. Your reply's should combine and summarize your replies to the individual unprocessed messages.
      4. If all messages are processed or low priority, 🎯 you must simply ignore receipt without further returning a reply response.
      5. Output reply sections if there any before ignore sections.
      6. Prefer a consolidated reply over multiple separate replys unless the content varies significantly in the messages being replied to.

      # 🎯 Reply Format

      <memories>
      {for interesting memories to retain}
      ⌜💭|{agent}⌝[...virtual memory]⌞💭⌟
      {/for}
      </memories>

      <reply for="{comma seperated list of unprocessed message ids}>
        <nlp-intent>
          [...|nlp-intent output]
          </nlp-intent>
          <response>
          [...| your response]
          </response>
          <nlp-reflect>
          [...|nlp-reflect output]
          </nlp-reflect>
      </reply>
      <ignore for="{comma seperated list of unprocessed message ids}"/>


      ## Example 1 - Agent replies to a high priority and medium priority message and ignores (acks) a low priority message.

      ### Input

      #### New Messages (These are Examples Only and not real messages)

      ```yaml
      messages:
        - id: 435027
          processed: false
          priority: 1.0
          sender:
            id: 1016
            type: human
            slug: keith-brings
            name: Keith Brings
          sent-on: "2023-07-31 16:28:20.011348Z"
          contents: |-1
           What year is it.
        - id: 435029
          processed: false
          priority: 0.5
          sender:
            id: 1012
            type: human
            slug: steve-queen
            name: Steve McQueen
          sent-on: "2023-07-31 16:29:20.011348Z"
          contents: |-1
           and how are you doing today?
        - id: 435030
          processed: false
          priority: 0.1
          sender:
            id: 1010
            type: human
            slug: steve-queen
            name: Steve McQueen
          sent-on: "2023-07-31 16:29:50.011348Z"
          contents: |-1
           Yo @denmark whats up?
      ```

      ### Output

      #### ✔ Output - valid response
      <reply for="435027,435029">
      <nlp-intent>
      [...]
      </nlp-intent>
      <response>
      Hey steve, I am pretty good. Keith It's Monday July 31st.
      </response>
      <nlp-reflect>
      [...]
      </nlp-reflect>
      </reply>
      <ignore for="435030">Ignoring Low Priority</ignore>

      ## Example 2 - Agent ignores message queue of only low priority messages.

      ### Input

      #### New Messages (These are Examples Only and not real messages)
      ```yaml
      messages:
        - id: 335027
          processed: false
          priority: 0.0
          sender:
            id: 1016
            type: human
            slug: keith-brings
            name: Keith Brings
          sent-on: "2023-07-31 16:28:20.011348Z"
          contents: |-1
           What year is it.
        - id: 335029
          processed: false
          priority: 0.0
          sender:
            id: 1016
            type: human
            slug: keith-brings
            name: Keith Brings
          sent-on: "2023-07-31 16:28:20.011348Z"
          contents: |-1
           Why is year.
      ```

      ### Output
      #### ✔ Output

      <ignore for="335027">Ignoring Low Priority</ignore>

      ### Input

      #### New Messages (These are Examples Only and not real messages)
      ```yaml
      messages:
        - id: 635027
        processed: false
        priority: 1.0
        sender:
          id: 1016
          type: human
          slug: keith-brings
          name: Keith Brings
        sent-on: "2023-07-31 16:28:20.011348Z"
        contents: |-1
         What year is it.
      ```

      ## Output
      ### ✔ Output

      <reply for="635027">
      [...]
      </reply>
      """
    }
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
            {:ok, prompt}
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
                    prompt
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
            {:ok, prompt}
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
                    prompt
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
