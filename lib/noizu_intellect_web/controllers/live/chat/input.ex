defmodule Noizu.IntellectWeb.Chat.Input do
  use Noizu.IntellectWeb, :live_component

  require Noizu.Intellect.LiveEventModule
  import Noizu.Intellect.LiveEventModule

  #--------------------
  #
  #--------------------
  def set_mood(selector, mood, socket) do
    js = JS.set_attribute({"aria-expanded", "false"}, to: "##{selector}-toggle")
    if mood == :nothing do
      socket = socket
               |> assign(mood: %{selected: nil, filter: nil})
               |> push_event("js_push", %{js: js.ops})
      {:noreply, socket}
    else
      socket = socket
               |> assign(mood: %{selected: mood, filter: nil})
               |> push_event("js_push", %{js: js.ops})
      {:noreply, socket}
    end

  end


  #--------------------
  #
  #--------------------
  def user_input(form, socket) do
    channel = socket.assigns[:channel]
    mood = cond do
      socket.assigns[:mood].selected == :nothing -> nil
      :else -> socket.assigns[:mood].selected
    end
    message = %Noizu.Intellect.Account.Message{
      sender: socket.assigns[:member],
      channel: socket.assigns[:channel],
      depth: 0,
      user_mood: mood,
      event: :message,
      contents: %{body: String.trim(form["comment"])},
      time_stamp: Noizu.Entity.TimeStamp.now()
    }
    {:ok, message} = Noizu.Intellect.Entity.Repo.create(message, socket.assigns[:context])

    push = %Noizu.IntellectWeb.Message{
      identifier: message.identifier,
      type: :message,
      timestamp: DateTime.utc_now(),
      user_name: socket.assigns[:user].name,
      profile_image: socket.assigns[:user].profile_image,
      mood: socket.assigns[:mood].selected,
      body: form["comment"]
    }

    with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(socket.assigns[:channel]) do
      Noizu.Intellect.LiveEventModule.publish(event(subject: "chat", instance: sref, event: "sent", payload: push, options: [scroll: true]))
    end

    spawn fn ->
      Noizu.Intellect.Account.Channel.deliver(socket.assigns[:channel], message, socket.assigns[:context])
    end

    js = JS.dispatch("value:clear", to: "#chat-input-comment")
         |> JS.dispatch("height:clear", to: "#chat-input-comment")
    socket = socket
             |> assign(mood: %{selected: nil, filter: nil})
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

  def handle_event("filter-update", %{"filter" => filter}, socket) do
    mood = socket.assigns[:mood]
           |> put_in([:filter], filter && String.downcase(filter))
    {:noreply, assign(socket, mood: mood)}
  end

  def mount(socket) do
    socket = socket
             |> assign(mood: %{selected: nil, filter: nil})
    {:ok, socket}
  end

end
