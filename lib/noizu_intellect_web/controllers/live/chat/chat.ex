defmodule Noizu.IntellectWeb.Message do
  defstruct [
    type: nil,
    glyph: nil,
    typing: false,
    timestamp: nil,
    user_name: nil,
    profile_image: nil,
    mood: nil,
    body: nil,
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
    <div class="bg-white shadow-md rounded p-2">
    <div class="mb-4">
      <.live_component module={Noizu.IntellectWeb.Chat.History}, id="project-chat-history" unique="main" messages={@messages} />
    </div>

    <div>
      <.live_component module={Noizu.IntellectWeb.Chat.Input}, id="project-chat-input" user={@active_user} channel={@active_channel} />
    </div>
    </div>

    """
  end

  #===========================
  #
  #===========================

  def handle_event(event, _, socket) do
    {:noreply, socket}
  end



  #===========================
  #
  #===========================
  def handle_info(info = event(subject: "chat", instance: _channel_sref, event: "typing", payload: message), socket) do
    Logger.error("HANDLE_INFO: #{inspect info}")
    socket = socket
             |> assign(messages: socket.assigns[:messages] ++ [message])
    {:noreply, socket}
  end
  def handle_info(info = event(subject: "chat", instance: _channel_sref, event: "sent", payload: message), socket) do
    Logger.error("HANDLE_INFO: #{inspect info}")

    socket = socket
             |> assign(messages: socket.assigns[:messages] ++ [message])
    {:noreply, socket}
  end


  #===========================
  #
  #===========================
  def mount(_, session, socket) do
    now = DateTime.utc_now()
    img = "a0074078-c6c3-465b-b210-edd7e5fd33be"
    messages = [
      %Noizu.IntellectWeb.Message{
        type: :event,
        timestamp: Timex.shift(now, days: -7),
        user_name: "Chelsea Hagon",
        profile_image: img,
        body: "created the invoice."
      },
      %Noizu.IntellectWeb.Message{
        type: :event,
        timestamp: Timex.shift(now, days: -6),
        user_name: "Chelsea Hagon",
        profile_image: img,
        body: "edited the invoice."
      },
      %Noizu.IntellectWeb.Message{
        type: :event,
        timestamp: Timex.shift(now, days: -5),
        user_name: "Chelsea Hagon",
        profile_image: img,
        body: "sent the invoice."
      },
      %Noizu.IntellectWeb.Message{
        type: :message,
        timestamp: Timex.shift(now, days: -3),
        user_name: "Chelsea Hagon",
        profile_image: img,
        mood: :loved,
        body: "Called client, they reassured me the invoice would be paid by the 27th."
      },
      %Noizu.IntellectWeb.Message{
        type: :event,
        timestamp: Timex.shift(now, days: -2),
        user_name: "Alex Current",
        profile_image: img,
        body: "Viewed the invoice."
      },
      %Noizu.IntellectWeb.Message{
        type: :event,
        glyph: :check,
        timestamp: DateTime.utc_now(),
        user_name: "Alex Current",
        profile_image: img,
        body: "Paid the invoice."
      },
    ]

    with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(session["active_channel"]) do
      Noizu.Intellect.LiveEventModule.subscribe(event(subject: "chat", instance: sref, event: "sent"))
      Noizu.Intellect.LiveEventModule.subscribe(event(subject: "chat", instance: sref, event: "typing"))
    end

    socket = socket
             |> assign(mood: session["mood"])
             |> assign(active_user: session["active_user"])
             |> assign(active_project: session["active_project"])
             |> assign(active_channel: session["active_channel"])
             |> assign(active_member: session["active_member"])
             |> assign(messages: messages)
    {:ok, socket}
  end
end
