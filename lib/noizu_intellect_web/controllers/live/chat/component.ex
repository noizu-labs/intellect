defmodule Noizu.IntellectWeb.Chat.Component do
  use Noizu.IntellectWeb, :live_component

  def render(assigns) do
    ~H"""
    """
  end

  attr :message, Noizu.IntellectWeb.Message, default: nil
  def event(assigns) do
    ~H"""
          <div class="absolute left-0 top-0 flex w-6 justify-center -bottom-6">
              <div class="w-px bg-gray-200"></div>
          </div>
          <div class="relative flex h-6 w-6 flex-none items-center justify-center bg-white">
              <%= cond do %>
                <% @message.glyph == :check -> %>
                  <svg class="h-6 w-6 text-indigo-600" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                    <path fill-rule="evenodd" d="M2.25 12c0-5.385 4.365-9.75 9.75-9.75s9.75 4.365 9.75 9.75-4.365 9.75-9.75 9.75S2.25 17.385 2.25 12zm13.36-1.814a.75.75 0 10-1.22-.872l-3.236 4.53L9.53 12.22a.75.75 0 00-1.06 1.06l2.25 2.25a.75.75 0 001.14-.094l3.75-5.25z" clip-rule="evenodd" />
                  </svg>
                <% :default -> %>
                  <div class="h-1.5 w-1.5 rounded-full bg-gray-100 ring-1 ring-gray-300"></div>
              <% end %>
          </div>
          <p class="flex-auto py-0.5 text-xs leading-5 text-gray-500"><span class="font-medium text-gray-900"><%= @message.user_name %></span> <%= @message.body %></p>
          <.elapsedTime since={@message.timestamp}/>
    """
  end


  attr :message, Noizu.IntellectWeb.Message, default: nil
  def message(assigns) do
    ~H"""
      <div class="absolute left-0 top-0 flex w-6 justify-center -bottom-6">
          <div class="w-px bg-gray-200"></div>
      </div>
      <img src={image_service(:profile, @message.profile_image)}  alt="" class="relative mt-3 h-6 w-6 flex-none rounded-full bg-gray-50"/>
      <div class="chat-message-block flex-auto rounded-md p-3 ring-1 ring-inset ring-gray-200 max-w-full overflow-x-auto">
          <div class="flex justify-between gap-x-4">
              <div class="py-0.5 text-xs leading-5 text-gray-500">

                  <%= if @message.mood && @message.mood != :nothing do %>
                        <span class="inline-block">
                          <.mood_glyph size={:small} mood={@message.mood} />
                          <span class="sr-only"><.mood_label mood={@message.mood} /></span>
                        </span>
                  <% end %>
              <span class="font-medium text-gray-900"><%= @message.user_name %>
              <span class="message-id">#<%= @message.identifier %></span>


              </span> commented</div>
              <.elapsedTime since={@message.timestamp}/>
          </div>
            <!-- <%# <div class="markdown-body"><%= raw(Earmark.as_html!(@message.body) |> Noizu.Intellect.HtmlModule.replace_script_tags() ) %></div> %> -->
          <div class="chat-message-body markdown-body"><%=  raw(Earmark.as_html!(@message.body, smartypants: false) |> Noizu.Intellect.HtmlModule.replace_script_tags() ) %></div>

      <%= if @message.meta do %>
      <div class="meta-details hidden">
        <%= for section <- @message.meta do %>
          <pre>
          <%= Ymlr.document!(section) %>
          </pre>
        <% end %>
      </div>
      <% end %>

      </div>
    """
  end

end

defimpl Poison.Encoder, for: Tuple do
  def encode(tuple,opts) do
    Poison.Encoder.encode("#{inspect tuple}", opts)
  end
end
