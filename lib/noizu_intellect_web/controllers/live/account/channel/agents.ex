defmodule Noizu.IntellectWeb.Account.Channel.Agents do
  use Noizu.IntellectWeb, :live_component

  require Noizu.Intellect.LiveEventModule
  import Noizu.Intellect.LiveEventModule
  import Noizu.IntellectWeb.CoreComponents



  #=========================
  #
  #=========================
  def show_agent(agent, socket) do
    with agents <- socket.assigns[:agents],
         {:ok, agent} <- Enum.find_value(agents, &(&1.identifier == agent && {:ok, &1}))
      do
      js = show_modal("#{socket.assigns[:id]}-show-agent-modal")
      socket = socket
               |> assign(selected: agent)
               |> push_event("js_push", %{js: js.ops})
      {:noreply, socket}
    else
      _ -> {:noreply, socket}
    end
  end

  #=========================
  #
  #=========================
  def handle_event("show:agent", %{"agent" => agent}, socket) do
    show_agent(String.to_integer(agent), socket)
  end


  #=========================
  #
  #=========================
  def update(assigns, socket) do
    socket = with {:ok, agents} <- Noizu.IntellectApi.Agents.by_project(assigns.project, assigns.context) do
               socket
               |> assign(agents: agents)
             else
               _ ->
                 # Error
                 socket
                 |> assign(agents: [])
             end
             |> assign(assigns)
             |> assign(selected: nil)
    {:ok, socket}
  end

end
