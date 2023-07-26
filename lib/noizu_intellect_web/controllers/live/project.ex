


defmodule Noizu.IntellectWeb.Project do
  use Noizu.IntellectWeb, :live_view
  import Noizu.IntellectWeb.CoreComponents
  def render(assigns) do
    ~H"""



    <div class="flex flex-row w-full min-h-[90vh] items-center content-center justify-self-center justify-center justify-items-center z-10">
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


    <div id="right-aside" class="relative z-10" aria-labelledby="slide-over-title" role="dialog" aria-expanded="false">
    <!-- Background backdrop, show/hide based on slide-over state. -->
    <!-- <div class="fixed inset-0"></div> -->


    <div class="aside-overlay z-10 fixed inset-0 overflow-hidden w-fit bg-black">


    <div class="absolute inset-0 overflow-hidden z-10 ">
      <div class="pointer-events-none  fixed inset-y-0 right-0 flex max-w-full pl-10">
        <!--
          Slide-over panel, show/hide based on slide-over state.

          Entering: "transform transition ease-in-out duration-500 sm:duration-700"
            From: "translate-x-full"
            To: "translate-x-0"
          Leaving: "transform transition ease-in-out duration-500 sm:duration-700"
            From: "translate-x-0"
            To: "translate-x-full"
        -->


        <div class="pointer-events-auto  w-screen max-w-md">


          <div phx-click={JS.set_attribute({"aria-expanded", "true"}, to: "#right-aside")} phx-click-away={JS.set_attribute({"aria-expanded", "false"}, to: "#right-aside")}
          class=".contents aside-contents flex h-full flex-col overflow-y-scroll bg-white py-6 shadow-xl z-50">
            <div class="px-4 sm:px-6">
              <div class="flex items-start justify-between pt-16">
                <h2 class="prose prose-xl  font-semibold text-gray-900" id="slide-over-title">Panel title</h2>
                <div class="ml-3 flex h-7 items-center">
                  <button phx-click={JS.set_attribute({"aria-expanded", "false"}, to: "#right-aside")} type="button" class="rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2">
                    <span class="sr-only">Close panel</span>
                    <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
            <div class="relative mt-6 flex-1 px-4 sm:px-6 z-20">
              <!-- Your content -->
                <.live_component module={Noizu.IntellectWeb.Account.Menu}, id="project-menu" />
        <.live_component module={Noizu.IntellectWeb.Account.Channel.Members}, class="" id="project-channel-members" />
        <.live_component module={Noizu.IntellectWeb.Account.Channel.Agents}, class="" id="project-channel-agents" />
      <%= live_render(@socket, Noizu.IntellectWeb.Issues, id: "project-issues", session: %{"some_key" =>
    "some_value"}) %>

            </div>
          </div>
        </div>
      </div>
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
