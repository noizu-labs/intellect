defmodule Noizu.IntellectWeb.Account.Channels do
  use Noizu.IntellectWeb, :live_component

  require Noizu.Intellect.LiveEventModule


  def update(assigns, socket) do
    socket = socket
             |> assign(assigns)
    channels = with {:ok, channels} <- Noizu.Intellect.Account.channels(socket.assigns[:project], socket.assigns[:context]) do
      channels
    else
      _ ->
        []
    end
    socket = socket
             |> assign(channels: channels)
    {:ok, socket}
  end


  def mount(socket) do
    socket = socket
             |> assign(channels: [])
    {:ok, socket}
  end

end
