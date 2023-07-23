defmodule Noizu.IntellectWeb.Chat.History do
  use Noizu.IntellectWeb, :live_view

  def handle_event(_, _, socket) do
    {:noreply, socket}
  end

  def mount(_, session, socket) do
    {:ok, socket}
  end
end
