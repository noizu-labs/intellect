


defmodule Noizu.IntellectWeb.Project do
  use Noizu.IntellectWeb, :live_view
  import Noizu.IntellectWeb.CoreComponents
  def render(assigns) do
    ~H"""



    <div class="flex flex-row w-full min-h-[90vh] items-end content-center justify-self-center justify-center justify-items-center z-10">
      <!-- center -->
      <div class="w-10/12 z-10">
      <%= live_render(
      @socket,
      Noizu.IntellectWeb.Chat,
      id: "project-chat",
      session: %{
        "mood" => %{selected: nil},
        "active_user" => @active_user,
        "active_project" => @active_project,
        "active_channel" => @active_channel,
        "active_member" => @active_member }
      ) %>
      </div>
    </div>


    <.side_bar id="right-aside">
        <.live_component module={Noizu.IntellectWeb.Account.Menu}, id="project-menu" />
        <.live_component module={Noizu.IntellectWeb.Account.Channel.Members}, class="" id="project-channel-members" />
        <.live_component module={Noizu.IntellectWeb.Account.Channel.Agents}, class="" id="project-channel-agents" />
      <.live_component module={Noizu.IntellectWeb.Account.Channels}, class="" id="project-channels" />
        <%= live_render(@socket, Noizu.IntellectWeb.Issues, id: "project-issues", session: %{"some_key" => "some_value"}) %>
    </.side_bar>







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
             |> assign(context: session["context"])
    {:ok, socket}
  end
end
