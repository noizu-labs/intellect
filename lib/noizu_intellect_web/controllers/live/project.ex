



defmodule Noizu.IntellectWeb.Project do
  use Noizu.IntellectWeb, :live_view

  def render(assigns) do
    ~H"""
    <pre>
    User: <%= @active_user.name %>
    Created On: <%= @active_user.time_stamp.created_on %>
    Project: <%= @active_project.slug %>
    Channel: <%= @active_channel.slug %>
    </pre>
    """
  end
  def render(assigns) do
    ~H"""
    <div class="w-full h-full">
    <div class="flex w-full h-full">
    <!-- Contacts List -->
    <div class="w-1/4 p-4 h-full">
      <%= live_render(
      @socket,
      Noizu.IntellectWeb.ContactForm,
      container: {:div, [class: "w-full h-full p-0 m-0"]},
      id: "project-agents",
      session: %{
        "active_user" => @active_user,
        "active_project" => @active_project,
        "active_channel" => @active_channel,
        "active_member" => @active_member}
      ) %>
    </div>

    <!-- Chat Area -->
    <div class="w-[60vw] p-0 h-[60%]">

    <%= live_render(
    @socket,
    Noizu.IntellectWeb.ChatForm,
    container: {:div, [class: "w-fit h-full p-0 m-0"]},
    id: "project-chat",
    session: %{
     "active_user" => @active_user,
     "active_project" => @active_project,
     "active_channel" => @active_channel,
     "active_member" => @active_member}
    ) %>
    </div>

    </div>
    </div>
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

  def mount(_, session, socket) do
    socket = socket
             |> assign(active_project: session["active_project"])
             |> assign(active_user: session["active_user"])
             |> assign(active_channel: session["active_channel"])
             |> assign(active_member: session["active_member"])
    {:ok, socket}
  end
end
