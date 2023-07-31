defmodule Noizu.Intellect.Prompt.ContextWrapper do
  @vsn 1.0
  defstruct [
    prompt: nil,
    minder: nil,
    vsn: @vsn
  ]


  def relevancy_prompt() do
    %__MODULE__{
      prompt: [system: """


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

      ## Goal

      Determine relevance scores for new message inputs, ranging from 0.0 (no relevance) to 1.0 (direct message). These scores indicate the intended recipient among channel members, based on the content of the message and the sender's previous interactions.

      ## Considerations

      1. If the sender previously addressed a specific member and the new message doesn't change the addressee (no "@" symbols or tonal shifts), consider it likely intended for the same recipient.
      2. If the sender's message aligns with a member's background, yet the intended recipient is unclear, assign a relevance score of 0.6.

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
      minder: """
      # Reminder: Conversation Flow

      Always assume that any new message from a sender is a continuation of their previous message, unless the content clearly indicates a response to a different prior message. Review the message history, considering messages sent by the sender, other users, and the time lapse between messages, until the most likely recipient of the sender's new message is identified.

      Note: The use of `@` followed by an agent's slug implies the message is targeted at that agent and likely now longer directed to the previous sender messages' recipients. For example, `@steve` suggests the agent with the slug `steve` is now the recipient.

      # Direction: Message Relevance

      For subsequent messages, compare their content with the `Message History` in reverse chronological order. This will help determine the relevance of the new message based on its content and the channel's message history.

      For instance, if a sender's new message continues their previous one and doesn't clearly suggest a new recipient or response to a preceding message, the relevance of the sender's previous message should apply.
      <%#
      <nlp-intent>
      {Provide a markdown table listing: message.id, message.sent-on, message.sender.slug, the most likely recipient(s) slugs, recipient weight(s), the message.id this is likely responding to, and reason for designation for the 5 most recent messages, sorted by message.sent-on.}
      </nlp-intent>
      %>
      ```format
      <relevance>
        {for each channel member|
          Consider each channel member. `@channel` and `@everyone` are special directives; if found in a message, treat it as if it had included the channel member's slug.
          For each member, provide a relevancy score between 0.0 (not relevant) and 1.0 (direct message) and explain your reasoning.}
        <relevancy for-user="{member.id}" for-message="{message.id | id of message most likely to be in response to given this weight.}" for-slug="{member.slug}" value="{value in [0.0,1.0] where 0.0 indicate message has nothing to do with channel member and 1.0 indicates this is a direct message to channel member.}">
        {Reasoning}
        </relevancy>
        {/for}
      </relevance>
      ```
      """
    }
  end

  def master_prompt() do
    %__MODULE__{
      prompt: [system: """
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
      @<%= @prompt_context.agent.slug %> reply to or ack the messages in the next operator request. Make your response brief, do not repeat information/messages already sent, reply to multiple related messages
      in a single consolidated reply. e.g. "Hello dave, keith, mike" in response to three separate greetings from dave keith and mike. Your responses should take into account previous message history but should not response specifically to previously process messages merely take their context into consideration.

      If a message's priority is <= 0.5 do not reply to it directly, simply ack receipt. It is okay to reply to a thread with only an ack response and no reply block.
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

      In your response, <%= @prompt_context.agent.slug %>, please adhere to the following guidelines. Ensure your reply is contextually relevant, considering the preceding conversation in this channel, including processed messages. Aim for a fluid conversation involving multiple participants, continuing from where you left off without repeating previously provided information.

      **Avoid** engaging in nonproductive conversations with other non-human actors. Do not respond to a message you've already replied to, unless there's a request for more information or your response adds value.

      ## Response Guidelines

      1. Avoid ack'ing or replying to previously processed messages.
      2. If a message's priority is ≤ 0.5, ack it without replying directly
         a. It is okay to have a empty response that only contains an ack tag and no reply due to all messages being low priority or processed it is better than unnecessarily responding to a message directed at someone else.
      3. Aim to respond to multiple messages simultaneously. Your response should combine and summarize your replies to the individual unprocessed messages.
      4. If all messages are processed or low priority, it is acceptable to only ack receipt without further reply.
      5. Output reply sections before ack sections.
      6. Prefer a consolidated response to multiple messages over multiple separate responses unless the content varies significantly.

      ### Reply Format
      The following format should be used when constructing a reply responses.

      <reply for="{comma seperated list of unprocessed message ids this reply is for}">
          <nlp-intent>
          [...|nlp-intent output]
          </nlp-intent>
          <response>
          [...| your reply]
          </response>
          <nlp-reflect>
          [...|nlp-reflect output]
          </nlp-reflect>
      </reply>

      ### Acknowledgement Format
      Use the following format to `ack`nowledge receipt of messages.

      <ack for="{comma seperated list of unprocessed message ids acknowledged but not replied to}"/>

      ## Response Format
      [...| a reply or ack or a mix of both response blocks.]

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
