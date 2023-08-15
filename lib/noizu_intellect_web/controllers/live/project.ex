


defmodule Noizu.IntellectWeb.Project do
  use Noizu.IntellectWeb, :live_view
  import Noizu.IntellectWeb.CoreComponents
  def render(assigns) do
    ~H"""




    <div class="fixed inset-0 w-32 right-0 h-[100%] pointer-events-none z-30">
    <div class="pointer-events-auto fixed right-3 top-16 pt-2 page-top-arrow z-50">
      <svg
    phx-click={JS.dispatch("scroll:top", to: "html")}
    xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
        <path stroke-linecap="round" stroke-linejoin="round" d="M15 11.25l-3-3m0 0l-3 3m3-3v7.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    </div>
    <div class="pointer-events-auto fixed page-bottom-arrow right-3 bottom-2 z-50">
      <svg
    phx-click={JS.dispatch("scroll:bottom", to: "html")}
    xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
        <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75l3 3m0 0l3-3m-3 3v-7.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    </div>
    </div>


    <.sidebar show={false} id="right-aside">



        <.live_component module={Noizu.IntellectWeb.Account.Menu}, id="project-menu" />
        <.live_component module={Noizu.IntellectWeb.Account.Channel.Members}, class="" id="project-channel-members" />
        <.live_component
          module={Noizu.IntellectWeb.Account.Channel.Agents},
          class=""
          id="project-channel-agents"
          project={@active_project_ref}
          channel={@active_channel_ref}
          member={@active_member_ref}
          context={@context}
        />
        <.live_component module={Noizu.IntellectWeb.Account.Channels},
          class=""
          project={@active_project_ref}
          context={@context}
          id="project-channels" />
        <%= live_render(@socket, Noizu.IntellectWeb.Issues, id: "project-issues", session: %{"some_key" => "some_value"}) %>
    </.sidebar>






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




    """
  end


  # collapse_sidebar

  def handle_event("collapse-sidebar", _, socket) do
    Noizu.IntellectWeb.Layouts.close_sidebar()
    {:noreply, socket}
  end


  def handle_event(event, params, socket) do
    IO.puts """
    uncaught #{__MODULE__}.handle_event
      event: #{inspect event}
      params: #{inspect params}
    """
    {:noreply, socket}
  end

  def mount(_, session, socket) do
    context = session["context"]
    (with {:ok, active_project_ref} <- Noizu.EntityReference.Protocol.ref(session["active_project"]),
          {:ok, active_channel_ref} <- Noizu.EntityReference.Protocol.ref(session["active_channel"]),
          {:ok, active_member_ref} <- Noizu.EntityReference.Protocol.ref(session["active_member"])
       do
       socket = socket
                |> assign(active_project_ref: active_project_ref)
                |> assign(active_channel_ref: active_channel_ref)
                |> assign(active_member_ref: active_member_ref)
                |> assign(mood: session["mood"])
                |> assign(active_user: session["active_user"])
                |> assign(active_project: session["active_project"])
                |> assign(active_channel: session["active_channel"])
                |> assign(active_member: session["active_member"])
                |> assign(context: session["context"])
                |> assign(error: nil)
       {:ok, socket}
     else
       error ->
         error = %Noizu.IntellectWeb.LiveViewError{
           title: Noizu.IntellectWeb.Gettext.gettext("Ref Failure"),
           body: Noizu.IntellectWeb.Gettext.gettext("Required Account Details Not Found."),
           error: error,
           trace: nil,
           time_stamp: DateTime.utc_now(),
           context: context
         }
         socket = socket
                  |> assign(error: error)
         {:ok, socket}
     end)
  end
end
