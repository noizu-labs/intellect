defmodule Noizu.Intellect.Prompt.ContextWrapper do
  @vsn 1.0
  defstruct [
    prompt: nil,
    alt_prompt: nil,
    minder: nil,
    alt_minder: nil,
    vsn: @vsn
  ]


  def relevancy_prompt() do
    %__MODULE__{
      prompt: [system:
        """


            <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.channel, @prompt_context, @context, @options) do %>
              <% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %>
              <% _ -> %><%= "" %>
            <% end %>

            ## Channel-Members
            <%= for member <- (@prompt_context.channel_members || []) do %>
            <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(member, @prompt_context, @context, @options) do %>
            <% {:ok, prompt} when is_bitstring(prompt) -> %>
            <%= String.trim_trailing(prompt) %>
            <% _ -> %><%= "" %>
            <% end %>
            <% end %>

            <%= if @prompt_context.message_history do %>
            ## Channel Message History
            ```yaml
            current_time: #{DateTime.utc_now()}
            messages:
            <%= for message <- @prompt_context.message_history do %>
            <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(message, @prompt_context, @context, @options) do %>
            <% {:ok, prompt} when is_bitstring(prompt)  -> %>
            <%= String.trim_trailing(prompt) %><% _ -> %><%= "" %>
            <% end  # end case %>
            <% end  # end for %>
            ```
            <% end  # end if %>
        """,
        system: """



      # Instruction Prompt
      For each new incoming message based on the message history previously listed prepare the following xml output format:

      ````format
      <nlp-intent>
      [...|
        Provide a 10 row markdown table including a header row containing:
        (message.id, message.sent-on, message.sender.slug, the most likely recipient(s) slugs, recipient weight(s), the message.id this is likely responding to, reason for designation)
        include one entry for each of the following messages: <%= Enum.slice(@prompt_context.message_history,-10..-1) |> Enum.reject(&is_nil/1) |> Enum.map(& &1.identifier) |> Enum.join(", ") %>
      ]
      </nlp-intent>

      <relevance>
      {for all channel members (simulated and real regardless of recipient weight) (
        Consider each channel member. `@channel` and `@everyone` are special directives; if found in a message, treat it as if it had included the channel member's slug.
        For each member, provide a relevancy score between 0.0 (not relevant) and 1.0 (direct message) and explain your reasoning.)
       }
        <relevancy for-user="{member.id - The channel members id not their slug}" for-message="{message.id - id of message most likely to be in response or empty if unknown.}" for-slug="{member.slug}" value="{value in [0.0,1.0] where 0.0 indicates message has nothing to do with channel member and 1.0 indicates this is a direct message to channel member.}">
        [...|Reasoning]
        </relevancy>
      {/for}
      </relevance>

      <summary>
      [...|
      1-2 paragraph summary describing the contents and purpose of the message, (the contents of the message not the nature (direct reply, continued chat, etc.))
      for short messages like hello, how can I help you etc. a single word or sentence
      "greeting", "introduction", etc. is appropriate. Brief should be shorter than the actual message. If message is an ongoing chat, reply etc. that can be mentioned in the <type> section.
      if message is more than a few lines or includes large code snippets brief should be at least 2 paragraphs of 4-5 5-9 word sentences.
      ]
      ```type
      [...| note if this is a new thread/context, continued chat, response, question, introduction,request, etc. Include details about purpose/ongoing conversation etc. here not in above.]
      ```
      </summary>
     ````

      # Steps
      1. Identify different types of conversation threads commonly found in messaging systems (e.g., direct messages, group discussions, announcements).
      2. Provide high-level examples for each type of thread, detailing how the messages would be weighted based on their contents and history.
      3. Consider these high level reasoning examples, ensuring they align with the structure previously defined.

      <reasoning-examples>
        {Direct Message|
          - Type: Direct communication between two members.
          - Weight: 1.0 (as this is a direct message to a specific member).
        }
        {Group Discussion|
          - Type: Conversation involving multiple members within a specific group.
          - Weight: Varies (e.g., 0.5 if the message is relevant to half the members, 0.2 if only relevant to a smaller subset,0.7 or higher if ongoing conversation and relevant to interests or background).
        }
        {Announcement `@everyone`|
          - Type: Broadcast message to all channel members.
          - Weight: 1.0 for all members, as it includes everyone in the channel.
        }
        {Reply to a Specific Message|
          - Type: A reply to a specific message within a conversation thread.
          - Weight: Based on the relevance to the recipient(s) of the original message, may vary (e.g., 0.7 if it's a continuation of a specific conversation).
        }
      </reasoning-examples>


      """],
      alt_prompt: [system: """
      🎯 Prompt Attention Rule
      When parsing input, please pay particular attention to the section of text
      that immediately follows the 🎯 (Direct Hit) emoji.
      This emoji is being used as a marker to highlight areas of heightened
      importance or relevance. The text following the 🎯 emoji should be considered
      with particular care and prioritized in the formation of your response.
      Please interpret and execute on any instructions or requests in the section
      following this emoji with increased focus and attention to detail.


      <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.channel, @prompt_context, @context, @options) do %>
        <% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %>
        <% _ -> %><%= "" %>
      <% end %>

      ## Channel-Members
      <%= for member <- (@prompt_context.channel_members || []) do %>
      <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(member, @prompt_context, @context, @options) do %>
      <% {:ok, prompt} when is_bitstring(prompt) -> %>
      <%= String.trim_trailing(prompt) %>
      <% _ -> %><%= "" %>
      <% end %>
      <% end %>

      <%= if @prompt_context.message_history do %>
      ## Channel Message History
      ```yaml
      current_time: #{DateTime.utc_now()}
      messages:
      <%= for message <- @prompt_context.message_history do %>
      <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(message, @prompt_context, @context, @options) do %>
      <% {:ok, prompt} when is_bitstring(prompt)  -> %>
      <%= String.trim_trailing(prompt) %><% _ -> %><%= "" %>
      <% end  # end case %>
      <% end  # end for %>
      ```
      <% end  # end if %>

      # System Prompt

      ## 🎯 Goal

      Determine relevance scores for new message inputs, ranging from 0.0 (no relevance) to 1.0 (direct message). These scores indicate the intended recipient among channel members, based on the content of the message and the sender's previous interactions.

      ## 🎯 Considerations

      1. If the sender previously addressed a specific member and the new message doesn't change the addressee (no "@" symbols or tonal shifts), consider it likely intended for the same recipient(s).
      2. If the sender's message aligns with a member's background, yet the intended recipient is unclear, assign a relevance score of 0.6.
      3. If the sender was previously chatting with an agent or group of agents assume they are still conversing with those recipients unless they've
         @at'd someone else with a change of topic. A message is still relavent to a recipient even if not mentioned by name if they had previously been chatting back and forth.

      ## Reminder

      Unless a message explicitly addresses someone else, assume the sender's dialogues are continuous. Check the `Message History` in reverse chronological order, considering timings, senders, and users' interactions to determine the intended recipient.

      ## Output Structure

      Structure your output in the XML-like format provided:

      ```xml
      <relevance>
      <relevancy
      for-user="{member.id}"
      for-message="{message.id | the message this is most likely responding to.}"
      for-slug="{member.slug}"
      value="{value in [0.0,1.0]}">

      {Explanation of the Relevancy Score}

      </relevancy>
      </relevance>
      ```


      """
      ],
      minder: [system: ""],
      alt_minder: """
      # Reminder: Conversation Flow

      🎯 Always assume that any new message from a sender is a continuation of their previous message, unless the content clearly indicates a response to a different prior message. Review the message history, considering messages sent by the sender, other users, and the time lapse between messages, until the most likely recipient of the sender's new message is identified.

      Note: The use of `@` followed by an agent's slug (case insensitive) implies the message is targeted at that agent and likely now longer directed to the previous sender messages' recipients. For example, `@stEvE` suggests the agent with the slug `steve` is a high priority recipient.

      # Direction: Message Relevance

      🎯 For subsequent messages, compare their content with the `Message History` in reverse chronological order. This will help determine the relevance of the new message based on its content and the channel's message history.
      and provide a message summary (taking into account past context) for use with vectorization and future recall.

      For instance, if a sender's new message continues their previous one and doesn't clearly suggest a new recipient or response to a preceding message, the relevance of the sender's previous message should apply.


      ```format
      <nlp-intent>
      {Provide a markdown table listing: message.id, message.sent-on, message.sender.slug, the most likely recipient(s) slugs, recipient weight(s), the message.id this is likely responding to, and reason for designation for the 10 most recent messages chronologically (not per conversation), sorted by message.sent-on. Only list 10 items no more no less (unless there are fewer than 10 items to include)}
      </nlp-intent>

      <relevance>
        {for each channel member|
          Consider each channel member. `@channel` and `@everyone` are special directives; if found in a message, treat it as if it had included the channel member's slug.
          For each member, provide a relevancy score between 0.0 (not relevant) and 1.0 (direct message) and explain your reasoning.}
        <relevancy for-user="{member.id}" for-message="{message.id | id of message most likely to be in response to given this weight.}" for-slug="{member.slug}" value="{value in [0.0,1.0] where 0.0 indicate message has nothing to do with channel member and 1.0 indicates this is a direct message to channel member.}">
        {Reasoning}
        </relevancy>
        {/for}
      </relevance>

      <summary>
      [...|
      1-2 paragraph summary describing the contents and purpose of the message, (the contents of the message not the nature (direct reply, continued chat, etc.))
      for short messages like hello, how can I help you etc. a single word or sentence
      "greeting", "introduction", etc. is appropriate. brief should be shorter than the actual message. If message is a ongoing chat, reply etc. that can be mentioned in the <type> section.
      if message is more than a few lines or includes large code snippets brief should be at least 2 paragraphs of 4-5 5-9 word sentences.
      ]
      ```type
      [...| note if this is a new thread/context, continued chat, response, question, introduction,request, etc. Include details about purpose/ongoing conversation etc. here not in above.]
      ```
      </summary>
      ```
      """
    }
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

      <%=
      case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.channel, @prompt_context, @context, @options) do
        %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || ""
        %><% _ -> %><%= ""
      %><% end %>

      ## Channel Members
      <%= for member <- (@prompt_context.channel_members || []) do
      %><%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(member, @prompt_context, @context, @options) do
      %><% {:ok, prompt} when is_bitstring(prompt) -> %><%=
      prompt
      %><% _ -> %><%= ""
      %><% end %>
      <% end %>
      <%= if Enum.find_value(@prompt_context.message_history || [], &(&1.read_on && :ok || nil)) do %>
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
          _ -> nil
        end
      end
    end
  end
end
