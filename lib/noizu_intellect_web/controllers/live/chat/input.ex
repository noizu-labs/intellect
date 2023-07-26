defmodule Noizu.IntellectWeb.Chat.Input do
  use Noizu.IntellectWeb, :live_component

  require Noizu.Intellect.LiveEventModule
  import Noizu.Intellect.LiveEventModule

  #--------------------
  #
  #--------------------
  def set_mood(selector, mood, socket) when mood in ["excited","loved","happy","sad","thumbsy","nothing"] do
    js = JS.set_attribute({"aria-expanded", "false"}, to: "##{selector}-toggle")
    socket = socket
             |> assign(mood: %{selected: String.to_atom(mood)})
             |> push_event("js_push", %{js: js.ops})
    {:noreply, socket}
  end


  #--------------------
  #
  #--------------------
  def user_input(form, socket) do
    message = %Noizu.IntellectWeb.Message{
      type: :message,
      timestamp: DateTime.utc_now(),
      user_name: socket.assigns[:user].name,
      profile_image: socket.assigns[:user].profile_image,
      mood: socket.assigns[:mood].selected,
      body: form["comment"]
    }
#
#
#    socket = socket
#             |> assign(messages: socket.assigns[:messages] ++ [append] )


    IO.inspect(socket.assigns[:channel])
    with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(socket.assigns[:channel]) |> IO.inspect(label: "sref") do
      IO.puts "PUBLISH"
      Noizu.Intellect.LiveEventModule.publish(event(subject: "chat", instance: sref, event: "sent", payload: message))
    end

    js = JS.dispatch("value:clear", to: "#chat-input-comment")
    socket = socket
             |> assign(mood: %{selected: nil})
             |> push_event("js_push", %{js: js.ops})
    {:noreply, socket}
  end

  #===========================
  #
  #===========================
  def handle_event("message:submit", form, socket) do
    user_input(form, socket)
  end

  def handle_event("set-mood", %{"mood" => mood, "id" => id}, socket) do
    set_mood(id, mood, socket)
  end

  def mount(socket) do
    socket = socket
             |> assign(mood: %{selected: nil})
    {:ok, socket}
  end

end
