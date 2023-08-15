defmodule Noizu.IntellectWeb.Account.Channel.Agents do
  use Noizu.IntellectWeb, :live_component

  require Noizu.Intellect.LiveEventModule
  import Noizu.IntellectWeb.CoreComponents
  import Ecto.Query


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

  def show_agent_chat_session(agent, socket) do
    with agents <- socket.assigns[:agents],
         {:ok, agent} <- Enum.find_value(agents, &(&1.identifier == agent && {:ok, &1}))
      do
      js = show_modal("#{socket.assigns[:id]}-select-agent-chat")
      member = socket.assigns[:member]
      context = socket.assigns[:context]
      sessions = Noizu.Intellect.Account.Agent.Chat.Session.Repo.sessions(agent, member, context)
      socket = socket
               |> assign(selected: agent)
               |> assign(sessions: sessions)
               |> push_event("js_push", %{js: js.ops})
      {:noreply, socket}
    else
      _ ->
        socket = socket
                 |> assign(sessions: [])
        {:noreply, socket}
    end
  end

  def create_chat_session(agent, socket) do
    with agents <- socket.assigns[:agents],
         {:ok, agent} <- Enum.find_value(agents, &(&1.identifier == agent && {:ok, &1})),
         {:ok, agent_ref} <- Noizu.EntityReference.Protocol.ref(agent)
      do
      {:ok, session} = %Noizu.Intellect.Account.Agent.Chat.Session{
        member: socket.assigns[:member],
        agent: agent_ref,
        details: %{title: "Chat Session", body: "Chat Session"},
        time_stamp: Noizu.Entity.TimeStamp.now()
      }  |> Noizu.Intellect.Entity.Repo.create(socket.assigns[:context])
      socket
    else
      _ -> socket
    end

    {:noreply, socket}
  end

  #=========================
  #
  #=========================
  def handle_event("show:agent", %{"agent" => agent}, socket) do
    show_agent(String.to_integer(agent), socket)
  end

  def handle_event("show:agent-chat", %{"agent" => agent}, socket) do
    show_agent_chat_session(String.to_integer(agent), socket)
  end

  def handle_event("create:session", %{"agent" => agent}, socket) do
    create_chat_session(String.to_integer(agent), socket)
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
             |> assign(sessions: [])
    {:ok, socket}
  end

end
