defmodule Noizu.IntellectWeb.Chat do
  use Noizu.IntellectWeb, :live_view

  def render(assigns) do
    IO.inspect(assigns, label: "ASSIGNS")
    ~H"""
    <div class="bg-white shadow-md rounded p-2">
    <div class="mb-4">
      <%= live_render(
      @socket,
      Noizu.IntellectWeb.Chat.History,
      id: "project-chat-history",
      session: %{}
      ) %>
    </div>

    <div>
      <.live_component module={Noizu.IntellectWeb.Chat.Input}, id="project-chat-input" mood={@mood}/>
    </div>
    </div>

    """
  end
  def set_mood(mood, socket) when mood in ["excited","loved","happy","sad","thumbsy","nothing"] do
    js = JS.set_attribute({"aria-selected", "false"}, to: "#noizu-chat-input-select-mood")
         |> JS.set_attribute({"aria-enabled", "false"}, to: "#noizu-chat-input-select-mood")
    socket = socket
             |> assign(mood: %{selected: String.to_atom(mood)})
             |> push_event("js_push", %{js: js.ops})
    {:noreply, socket}
  end


  def handle_event("set-mood:" <> mood, _, socket) do
    set_mood(mood, socket)
  end

  def handle_event(event, _, socket) do
    {:noreply, socket}
  end

  def mount(_, session, socket) do
    socket = socket
             |> assign(mood: session["mood"])
    {:ok, socket}
  end
end
