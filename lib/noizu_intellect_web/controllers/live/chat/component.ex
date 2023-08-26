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

      <div
        aria-selected="tab-1"
        id={"chat-message-#{@message.identifier}"}
        class="chat-message-block flex-auto rounded-md p-3 ring-1 ring-inset ring-gray-200 max-w-full overflow-x-auto">
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

              <span class="w-1/6 flex flex-row justify-end">
                <.elapsedTime since={@message.timestamp}/>
                <span>
                  <%= if @message.bookmark do %>
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
    <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 3.75V16.5L12 14.25 7.5 16.5V3.75m9 0H18A2.25 2.25 0 0120.25 6v12A2.25 2.25 0 0118 20.25H6A2.25 2.25 0 013.75 18V6A2.25 2.25 0 016 3.75h1.5m9 0h-9" />
    </svg>
                  <% else %>
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
    <path stroke-linecap="round" stroke-linejoin="round" d="M17.593 3.322c1.1.128 1.907 1.077 1.907 2.185V21L12 17.25 4.5 21V5.507c0-1.108.806-2.057 1.907-2.185a48.507 48.507 0 0111.186 0z" />
    </svg>
                  <% end %>
                </span>
              </span>

          </div>

          <div class="chat-message-body">

    <div >
    <div class="sm:hidden">
    <label for="tabs" class="sr-only">Select a tab</label>
    <!-- Use an "onChange" listener to redirect the user to the selected tab URL. -->
    <select id="tabs" name="tabs" class="block w-full rounded-md border-gray-300 focus:border-indigo-500 focus:ring-indigo-500">
      <option selected>Response</option>
      <option>Raw</option>
      <option selected>Meta</option>
    </select>
    </div>
    <div class="hidden sm:block">
    <div class="border-b border-gray-200">
      <nav class="-mb-px flex space-x-8" aria-label="Tabs">
        <a
          href="#"
          phx-click={JS.set_attribute({"aria-selected", "tab-1"}, to: "#chat-message-#{@message.identifier}")}
          class="tab group tab-1">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 01.865-.501 48.172 48.172 0 003.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0012 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018z" />
          </svg>
          <span>Response</span>
        </a>
        <a
          href="#"
          phx-click={JS.set_attribute({"aria-selected", "tab-2"}, to: "#chat-message-#{@message.identifier}")}
          class="tab group tab-2">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M17.25 6.75L22.5 12l-5.25 5.25m-10.5 0L1.5 12l5.25-5.25m7.5-3l-4.5 16.5" />
          </svg>
          <span>Raw</span>
        </a>
        <a
          href="#"
          phx-click={JS.set_attribute({"aria-selected", "tab-3"}, to: "#chat-message-#{@message.identifier}")}
          class="tab group tab-3">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 9h3.75M15 12h3.75M15 15h3.75M4.5 19.5h15a2.25 2.25 0 002.25-2.25V6.75A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25v10.5A2.25 2.25 0 004.5 19.5zm6-10.125a1.875 1.875 0 11-3.75 0 1.875 1.875 0 013.75 0zm1.294 6.336a6.721 6.721 0 01-3.17.789 6.721 6.721 0 01-3.168-.789 3.376 3.376 0 016.338 0z" />
          </svg>
          <span>Meta</span>
        </a>
      </nav>
    </div>
    </div>
    </div>
              <div class="tab-page tab-1 markdown-body">
                <%=  raw(Earmark.as_html!(@message.body, smartypants: false) |> Noizu.Intellect.HtmlModule.replace_script_tags() ) %>
              </div>
              <pre class="tab-page tab-2 align-top"><%=  @message.body %></pre>
              <div class="tab-page tab-3 align-top">
                 <%= if @message.meta do %>


                <%= if is_bitstring(@message.meta) do %>
                  <div class="meta-details">
                    <pre>
                    <%= @message.meta %>
                    </pre>
                  </div>
                <% else %>
                  <h2>Response</h2>
                  <div class="meta-details">
                    <pre>
                    <%= Ymlr.document!(@message.meta["response"]) %>
                    </pre>
                  </div>

                  <h2>Raw</h2>
                  <div class="meta-details">
                    <pre>
                    <%= Ymlr.document!(@message.meta["raw_reply"]) %>
                    </pre>
                  </div>

                  <h2>Messages</h2>
                  <%= for msg <- @message.meta["messages"] do %>
                    <h3><%= msg["role"] %></h3>
                    <div class="meta-details py-4">
                      <pre>
<%= msg["content"] %>
                      </pre>
                    </div>
                  <% end %>

                  <h2>Settings</h2>
                  <div class="meta-details">
                    <pre>
                    <%= Ymlr.document!(@message.meta["settings"]) %>
                    </pre>
                  </div>
                <% end %>

                <% else %>
                  <div class="meta-details">
                  [NONE]
                  </div>

                <% end %>
              </div>
    </div>

    <div class="w-full flex flex-row justify-end">
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
      <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12.76c0 1.6 1.123 2.994 2.707 3.227 1.087.16 2.185.283 3.293.369V21l4.076-4.076a1.526 1.526 0 011.037-.443 48.282 48.282 0 005.68-.494c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0012 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018z" />
      </svg>
    </div>


      </div>
    """
  end

end

defimpl Poison.Encoder, for: Tuple do
  def encode(tuple,opts) do
    Poison.Encoder.encode("#{inspect tuple}", opts)
  end
end
