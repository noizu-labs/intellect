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
    push = %Noizu.IntellectWeb.Message{
      type: :message,
      timestamp: DateTime.utc_now(),
      user_name: socket.assigns[:user].name,
      profile_image: socket.assigns[:user].profile_image,
      mood: socket.assigns[:mood].selected,
      body: form["comment"]
    }

    message = %Noizu.Intellect.Account.Message{
      sender: socket.assigns[:member],
      channel: socket.assigns[:channel],
      depth: 0,
      user_mood: nil,
      event: :message,
      contents: %{body: String.trim(form["comment"])},
      time_stamp: Noizu.Entity.TimeStamp.now()
    }
    {:ok, message} = Noizu.Intellect.Entity.Repo.create(message, socket.assigns[:context])

    with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(socket.assigns[:channel]) do
      Noizu.Intellect.LiveEventModule.publish(event(subject: "chat", instance: sref, event: "sent", payload: push, options: [scroll: true]))
    end

    spawn fn ->
      Noizu.Intellect.Account.Channel.deliver(socket.assigns[:channel], message, socket.assigns[:context])
    end

    js = JS.dispatch("value:clear", to: "#chat-input-comment")
         |> JS.dispatch("height:clear", to: "#chat-input-comment")
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
