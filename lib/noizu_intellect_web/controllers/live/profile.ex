defmodule Noizu.IntellectWeb.Profile do
  use Noizu.IntellectWeb, :live_view
  import Noizu.IntellectWeb.CoreComponents
  def render(assigns) do
    ~H"""
    [Profile]
    """
  end


  # collapse_sidebar
  def handle_event("collapse-sidebar", _, socket) do
    Noizu.IntellectWeb.Layouts.close_sidebar()
    {:noreply, socket}
  end

  def handle_event(_, _, socket) do
    {:noreply, socket}
  end

  def mount(conn, session, socket) do
    context = Noizu.Context.system()
    with {:ok, active_user = %Noizu.Intellect.User{}, _} <- Noizu.IntellectWeb.Guardian.resource_from_token(session["guardian_default_token"]) |> IO.inspect
      do
      socket = socket
               |> assign(active_user: active_user)
      {:ok, socket}
    else
      _ ->
        socket = socket
                 |> redirect(to: "/")
        {:ok, socket}
    end
  end
end
