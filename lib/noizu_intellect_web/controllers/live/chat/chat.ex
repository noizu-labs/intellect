defmodule Noizu.IntellectWeb.Message do
  defstruct [
    identifier: nil,
    type: nil,
    glyph: nil,
    typing: false,
    timestamp: nil,
    user_name: nil,
    user: nil,
    profile_image: nil,
    mood: nil,
    body: nil,
    meta: nil,
    state: :sent,
  ]
end

defmodule Noizu.IntellectWeb.Chat do
  use Noizu.IntellectWeb, :live_view
  import Noizu.IntellectWeb.Nav.Tags
  require Logger
  require Noizu.Intellect.LiveEventModule
  import Noizu.Intellect.LiveEventModule
  def render(assigns) do
    ~H"""
    <%= unless @error do %>
    <div class="bg-white shadow-md rounded h-full p-2 mt-4 flex flex-col">
      <div id="project-chat-history-container" class="m-0 p-0 pr-4 min-h-[60vh] flex flex-col  ">
        <.live_component module={Noizu.IntellectWeb.Chat.History}, id="project-chat-history" unique="main" messages={@messages} />
      </div>

    </div>

    <div class="chat-spacer">
    </div>

    <div class="fixed bottom-0 left-0 h-36 w-full">
     <.live_component
        module={Noizu.IntellectWeb.Chat.Input},
        id="project-chat-input"
        user={@active_user}
        channel={@active_channel_ref}
        project={@active_project_ref}
        member={@active_member}

      />
    </div>
    <% else %>
      <div class="w-full h-[90vh] flex flex-col">
        <div class="my-auto">
          <.display_error id="chat-error" error={@error}/>
        </div>
      </div>
    <% end %>


    """
  end

  #===========================
  #
  #===========================

  def handle_event("channel:switch", %{"channel" => channel}, socket) do
    context = socket.assigns[:context]
    with {:ok, channel} <- Noizu.Intellect.Account.channel_by_slug(socket.assigns[:active_project], channel, socket.assigns[:context]),
         {:ok, channel_ref} <- Noizu.EntityReference.Protocol.ref(channel),
         {:ok, channel_sref} <- Noizu.EntityReference.Protocol.sref(channel),
         {:ok, messages} <- Noizu.IntellectApi.Messages.recent(channel_ref, context, limit: 250)
      do


      Noizu.Intellect.LiveEventModule.unsubscribe(event(subject: "chat", instance: socket.assigns[:active_channel_sref], event: "sent"))

      socket = socket
               |> assign(active_channel: channel)
               |> assign(active_channel_ref: channel_ref)
               |> assign(active_channel_sref: channel_sref)


         Noizu.Intellect.LiveEventModule.subscribe(event(subject: "chat", instance: channel_sref, event: "sent"))
         messages = messages
                    |> Noizu.Intellect.LiveView.Encoder.encode!(context)
                    |> Enum.reverse()
         socket = socket
                  |> assign(messages: messages)
                  |> assign(error: nil)


      {:noreply, socket}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event(event, _, socket) do
    IO.puts "UNHANDLED EVENT: #{inspect event}"
    {:noreply, socket}
  end



  #===========================
  #
  #===========================
#  def handle_info(info = event(subject: "chat", instance: _channel_sref, event: "typing", payload: message, options: options), socket) do
#    socket = socket
#             |> assign(messages: socket.assigns[:messages] ++ [message])
#    {:noreply, socket}
#  end
  def handle_info(info = event(subject: "chat", instance: _channel_sref, event: "sent", payload: message, options: options), socket) do
    messages = socket.assigns[:messages] ++ [message]
    socket = socket
             |> assign(messages: messages)
             |> then(
                  fn(socket) ->
                    cond do
                      options[:scroll] ->
                        js = JS.dispatch("scroll:bottom", to: "html")
                             socket
                             |> push_event("js_push", %{js: js.ops})
                      :else -> socket
                    end
                  end)
    {:noreply, socket}
  end


  #===========================
  #
  #===========================
  def update(assigns, socket) do
    IO.puts "UPDATE? #{inspect assigns}"
    {:ok, socket}
  end

  def mount(_, session, socket) do
    context = session["context"]

    (with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(session["active_channel"]),
          {:ok, active_project_ref} <- Noizu.EntityReference.Protocol.ref(session["active_project"]),
          {:ok, active_channel_ref} <- Noizu.EntityReference.Protocol.ref(session["active_channel"]),
          {:ok, active_member_ref} <- Noizu.EntityReference.Protocol.ref(session["active_member"]),
          {:ok, messages} <- Noizu.IntellectApi.Messages.recent(active_channel_ref, context, limit: 250)
       do
       Noizu.Intellect.LiveEventModule.subscribe(event(subject: "chat", instance: sref, event: "sent"))
       messages = messages
                  |> Noizu.Intellect.LiveView.Encoder.encode!(context)
                  |> Enum.reverse()

#       error = try do
#         raise ArgumentError, "Example Error Raise"
#         rescue e ->
#           %Noizu.IntellectWeb.LiveViewError{
#              title: Noizu.IntellectWeb.Gettext.gettext("Argument Error"),
#              body: Noizu.IntellectWeb.Gettext.gettext("Demo of Error Functionality"),
#              error: e,
#              trace: __STACKTRACE__,
#              time_stamp: DateTime.utc_now(),
#              context: context
#           }
#       end
       socket = socket
                |> assign(active_project_ref: active_project_ref)
                |> assign(active_channel_ref: active_channel_ref)
                |> assign(active_channel_sref: sref)
                |> assign(active_member_ref: active_member_ref)
                |> assign(mood: session["mood"])
                |> assign(active_user: session["active_user"])
                |> assign(active_project: session["active_project"])
                |> assign(active_channel: session["active_channel"])
                |> assign(active_member: session["active_member"])
                |> assign(messages: messages)
                |> assign(error: nil)
       {:ok, socket}
     else
       error ->
     error = %Noizu.IntellectWeb.LiveViewError{
                    title: Noizu.IntellectWeb.Gettext.gettext("Ref Failure"),
                    body: Noizu.IntellectWeb.Gettext.gettext("Required Account Details Not Found."),
                    error: error,
                    trace: nil,
                    time_stamp: DateTime.utc_now(),
                    context: context
                 }

         socket = socket
                  |> assign(error: error)
         {:ok, socket}
     end)


  end
end
