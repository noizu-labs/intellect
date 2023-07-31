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
      # System Prompt
      You're task is to scan the following channel member definitions, the prior `Message History` and new message input. Then the new message input and
      and channel member determine a relevancy weights in [0.0,1.0] describing how likely it is
      that the user provided message is meant for the channel members based on it's content's and the content's sender's and likely recipients of previous messages under `Message History`.

      If the previous message from the same sender in the message history section was directed at a channel member and nothing about the content of the senders new message
      implies they are now talking to someone else then the new message from that sender would also apply to the previous member, and if the previous message from the same sender recipient is unclear than
      consider previous messages from message history going back in time until the likely recipient is determined. If the sender was previously talking to a channel member recently and has started a new query but the
      message does not indicate a change of recipient based on at symbols or content/tone then it likely is meant to continue to refer to the previous recipients. If you are unable to determine who the user is
      talking too but the question matches the background of a channel member then consider it a low possibility 0.6 that the message was directed at the channel members with related experience.

      ## Important Reminder Prompt
      Any new message by a sender should always be assumed to be a continuation of their previous message unless by content it is clear they are replying to a different prior message between it and their previous message.
      Walk down message history taking into account messages sent by sender, messages sent by other users, and time between messages as far back as possible until you've determined the likely target recipient of the senders new message.
      Even if message is the start of a new thought it should be assumed to still be targeted at previous recipient if no one else has been at'd and it does not appear to be replying to an earlier message.

      ## Output Format
      <relevance>
        <relevancy for-user="{member.id}" for-message="{message.id | id of message most likely to be in response to given this weight.}" for-slug="{member.slug}" value="{value in [0.0,1.0] where 0.0 indicate message has nothing to do with channel member and 1.0 indicates this is a direct message to channel member.}">
        {Reasoning for Relevancy Score}
        </relevancy>
      </relevance>

      <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(@prompt_context.channel, @prompt_context, @context, @options) do %>
        <% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %>
        <% _ -> %><%= "" %>
      <% end %>

      ## Members
      <%= for member <- (@prompt_context.channel_members || []) do %>
<%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(member, @prompt_context, @context, @options) do %>
<% {:ok, prompt} when is_bitstring(prompt) -> %>
### Member ID:<%= member.identifier %>
<%= prompt %>
<% _ -> %><%= "" %>
<% end %>
      <% end %>

      <%= if @prompt_context.message_history do %>
      # Message History
      current_time: #{DateTime.utc_now()}
        <%= for message <- @prompt_context.message_history do %>
          <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(message, @prompt_context, @context, @options) do %>
            <% {:ok, prompt} when is_bitstring(prompt)  -> %>
      <%= prompt %>
            <% _ -> %><%= "" %>
          <% end  # end case %>
        <% end  # end for %>
      <% end  # end if %>

      """
      ],
      minder: """
      # Important Reminder Prompt
      Any new message by a sender should always be assumed to be a continuation of their previous message unless by content it is clear they are replying to a different prior message between it and their previous message.
      Walk down message history taking into account messages sent by sender, messages sent by other users, and time between messages as far back as possible until you've determined the likely target recipient of the senders new message.
      Even if message is the start of a new thought it should be assumed to still be targeted at previous recipient if no one else has been at'd and it does not appear to be replying to an earlier message.

      ## The `@` followed by an agent's slug indicates a message is likely directed /at'd at that agent. E.g. @steve means the agent with the slug steve is the recipient.

      # Direction Prompt
      For the user provided messages following this message compare their contents to the messages above listed under  `Message History` going back chronologically in time in order to determine the new message's relevancy based on it's content and message history
      for all channel members. For instance if a new message from a sender is a continuation of their previous message and does not by it's content indicate a new recipient or that it is responding to a message preceding it then the relevancy map of the senders previous message
      should then apply.

      ```format
      <nlp-intent>
      {a markdown table listing (message.id, message.sent-on, message.sender, most likely channel-member recipient(s), most likely recipient weight(s), id of message this this message.id most likely was in response to., reason) for the 10 most recent messages sorted by sent-on}
      </nlp-intent>
      <relevance>
        {for each channel member listed above|  Keep in mind `@channel` and `@everyone` are special case insensitive directives and when in a message's content should be treated as though it had also stated @{channel-member}}
        <relevancy for-user="{member.id}" for-message="{message.id | id of message most likely to be in response to given this weight.}" for-slug="{member.slug}" value="{value in [0.0,1.0] where 0.0 indicate message has nothing to do with channel member and 1.0 indicates this is a direct message to channel member.}">
        {Reasoning for Relevancy Score and the relevancy score for this channel member - {sender.id of new message sender}-{sender.slug of new message sender} {message.id | of the previous message sent by the sender of new message.}}
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

      ## Members
      <%= for member <- (@prompt_context.channel_members || []) do
      %><%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(member, @prompt_context, @context, @options) do
      %><% {:ok, prompt} when is_bitstring(prompt) -> %>
      ### Member ID:<%= member.identifier %>
      <%= "\n" <> String.trim(prompt)
      %><% _ -> %><%= ""
      %><% end %>
      <% end %>
      <%= if Enum.find_value(@prompt_context.message_history || [], &(&1.read_on && :ok || nil)) do %>
      # Message History
      <%= for message <- @prompt_context.message_history do %><%= case message.read_on && Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(message, @prompt_context, @context, @options) do %><% {:ok, prompt} when is_bitstring(prompt)  -> %><%= prompt %><% _ -> %><%= "" %><% end #end case
      %><% end # end for
      %><% end # end if %>

      # Reply Direction Prompt
      @<%= @prompt_context.agent.slug %> reply to or acknowledge the messages in the next operator request. Make your response brief, do not repeat information/messages already sent, reply to multiple related messages
      in a single consolidated reply. e.g. "Hello dave, keith, mike" in response to three separate greetings from dave keith and mike. Your responses should take into account previous message history but should not response specifically to previously process messages merely take their context into consideration.

      If a message's priority is <= 0.5 do not reply to it directly, simply ack receipt.
      """,
      user: """
      Are you suppose to respond to messages of priority 0.0?
      """,
      assistant: """
      No, if a message's priority is <= 0.5, I should not reply to it directly. Instead, I will simply acknowledge receipt of the message. Thank you for bringing this to my attention.
      """,
      user: """
      #  Master Prompt Multi Message Response Prompt
      <%= @prompt_context.agent.slug %> Follow the below rules for your reply.
      Your reply(s) should be based on the conversation so far in this channel including processed messages. Your reply should be part of a natural back and forth conversation with multiple other participants.
      You should continue where you left off in replying to specific senders and the overall chat channel, you should not repeat messages that are similar/identical to messages you or other members have already provided.
      You should not engage in back and forth dead-end conversations between other non human senders, or reply to a message you've already replied to unless more information has been requested or will be provided by your response.
      A dead-end conversation is a back and forth conversation between non human actors that add no value to the chat often consisting of back and forth greetings/offers to help, etc with no actual work performed.


      ## Response Rules
      1. Do not ack or reply to previously processed messages.
      2. If a message's priority is <= 0.5 do not reply to it directly, simply ack receipt.
      3. You should try to reply to multiple messages together at once by constructing a reply that combines and summarizes your responses to the individual unprocessed messages.
      4. It is okay to ack all messages and not reply other than to ack receipt if all messages are already processed or low priority.
      5. Output reply sections first followed by ack sections.
      6. You should reply to multiple messages at once rather than returning multiple separate replies unless their content is significantly different.
          ## Reply Format
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

          ## Ack Format
          <ack for="{comma seperated list of unprocessed message ids acknowledged but not replied to}"/>

      # New Messages
      - If a message's priority is <= 0.5 do not reply to it directly, simply ack receipt.

      current_time: #{DateTime.utc_now()}
      <%= for message <- @prompt_context.message_history || [] do %><%= case is_nil(message.read_on) && Noizu.Intellect.Prompt.DynamicContext.Protocol.prompt(message, @prompt_context, @context, @options) do %><% {:ok, prompt} when is_bitstring(prompt)  -> %><%= prompt %><% e -> %><%= "" %><% end %><% end %>


      """
      ],
      minder: """
      <%= case Noizu.Intellect.Prompt.DynamicContext.Protocol.minder(@prompt_context.nlp_prompt_context, @prompt_context, @context, @options) do %><% {:ok, prompt} when is_bitstring(prompt) -> %><%= prompt || "" %><% _ -> %><%= "" %><% end # end case %>
      """
    }
  end

  defimpl Noizu.Intellect.Prompt.DynamicContext.Protocol do
    def prompt(subject, prompt_context, context, options) do
      with {:ok, assigns} <- Noizu.Intellect.Prompt.DynamicContext.assigns(prompt_context, context, options) do
        case subject.prompt do
          prompt when is_bitstring(prompt) ->
            prompt = EEx.eval_string(prompt, [assigns: assigns], trim: true)
            {:ok, prompt}
          {type, prompt} when is_bitstring(prompt) ->
            prompt = EEx.eval_string(prompt, [assigns: assigns], trim: true)
            {:ok, {type, prompt}}
          prompts when is_list(prompts) ->
            prompts = Enum.map(prompts,
              fn (prompt) ->
                case prompt do
                  prompt when is_bitstring(prompt) ->
                    prompt = EEx.eval_string(prompt, [assigns: assigns], trim: true)
                    prompt
                  {type, prompt} when is_bitstring(prompt) ->
                    prompt = EEx.eval_string(prompt, [assigns: assigns], trim: true)
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
      with {:ok, assigns} <- Noizu.Intellect.Prompt.DynamicContext.assigns(prompt_context, context, options) do
        case subject.minder do
          prompt when is_bitstring(prompt) ->
            prompt = EEx.eval_string(prompt, [assigns: assigns], trim: true)
            {:ok, prompt}
          {type, prompt} when is_bitstring(prompt) ->
            prompt = EEx.eval_string(prompt, [assigns: assigns], trim: true)
            {:ok, {type, prompt}}
          prompts when is_list(prompts) ->
            prompts = Enum.map(prompts,
              fn (prompt) ->
                case prompt do
                  prompt when is_bitstring(prompt) ->
                    prompt = EEx.eval_string(prompt, [assigns: assigns], trim: true)
                    prompt
                  {type, prompt} when is_bitstring(prompt) ->
                    prompt = EEx.eval_string(prompt, [assigns: assigns], trim: true)
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
