defmodule Noizu.IntellectWeb.Message do
  defstruct [
    identifier: nil,
    type: nil,
    glyph: nil,
    typing: false,
    timestamp: nil,
    user_name: nil,
    user: nil,
    profile_image: nil,
    mood: nil,
    body: nil,
    meta: nil,
    bookmark: false,
    state: :sent,
  ]
end

defmodule Noizu.IntellectWeb.Chat do
  use Noizu.IntellectWeb, :live_view
  require Logger
  require Noizu.Intellect.LiveEventModule
  import Noizu.Intellect.LiveEventModule
  def render(assigns) do
    ~H"""
    <%= unless @error do %>

    <div class="w-full p-1 mt-2 flex flex-row justify-center align-center text-center">
        <div class="prose-xl"><%= @active_channel.details.title %></div>
        <%= if @active_channel.type != :channel  do %>
        <span class="pl-1 my-auto text-small" phx-click={show_modal("channel-#{@active_channel.identifier}-edit")}>
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L6.832 19.82a4.5 4.5 0 01-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 011.13-1.897L16.863 4.487zm0 0L19.5 7.125" />
          </svg>
        </span>
        <% end %>
    </div>

    <div class="bg-white shadow-md rounded h-full p-2 mt-4 flex flex-col">
      <div id="project-chat-history-container" class="m-0 p-0 pr-4 min-h-[60vh] flex flex-col  ">
        <.live_component module={Noizu.IntellectWeb.Chat.History}, id="project-chat-history" unique="main" messages={@messages} />
      </div>

    </div>

    <div class="chat-spacer">
    </div>

    <div class="fixed bottom-0 left-0 h-36 w-full">
     <.live_component
        module={Noizu.IntellectWeb.Chat.Input},
        id="project-chat-input"
        user={@active_user}
        channel={@active_channel_ref}
        project={@active_project_ref}
        member={@active_member}

      />
    </div>
    <% else %>
      <div class="w-full h-[90vh] flex flex-col">
        <div class="my-auto">
          <.display_error id="chat-error" error={@error}/>
        </div>
      </div>
    <% end %>



    <.modal show={false} title="Edit Channel Name" class="fixed" id={"channel-#{@active_channel.identifier}-edit"}>
        <form
           phx-submit="edit:channel"
           phx-value-channel={@active_channel.identifier}
           phx-value-modal={"channel-#{@active_channel.identifier}-edit"}
       >
          <input name="title" type="text" value={@active_channel.details.title} />
           <button type="submit" class="rounded-md bg-red-200 px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-red-300" aria-label="Save">save</button>
        </form>
    </.modal>

    """
  end


  def switch_to_session(session, modal, socket) do
    context = socket.assigns[:context]

    with {:ok, session} <- Noizu.Intellect.Account.Agent.Chat.Session.entity(session, socket.assigns[:context]),
         {:ok, agent_ref} <- Noizu.EntityReference.Protocol.ref(session.agent),
         {:ok, channel} <- Noizu.EntityReference.Protocol.entity(session.channel, socket.assigns[:context]),
         {:ok, channel_ref} <- Noizu.EntityReference.Protocol.ref(session.channel)
      do
      js = hide_modal("#{modal}")
      socket = socket
               |> assign(active_channel_ref: channel_ref)
               |> assign(active_channel: channel)
               |> assign(view: :session)
               |> push_event("js_push", %{js: js.ops})
      Noizu.Intellect.Service.Agent.Ingestion.fetch({agent_ref, channel_ref}, :state, context)  |> IO.inspect()
      channel_switch(channel, socket)
    else
      _ -> {:noreply, socket}
    end
  end


  def create_chat_session(agent_id, modal, socket) do
    context = socket.assigns[:context]
    current_time = DateTime.utc_now()
    IO.puts "CREATE CHAT SESSION"
    with agents <- socket.assigns[:agents],
         {:ok, agent} <- Enum.find_value(agents, &(&1.identifier == agent_id && {:ok, &1})),
         {:ok, agent_ref} <- Noizu.EntityReference.Protocol.ref(agent),
         {:ok, channel} <- %Noizu.Intellect.Account.Channel{
                             slug: nil,
                             account: socket.assigns[:active_project_ref],
                             type: :session,
                             details: %{title: "Chat Session", body: "Chat Session"},
                             time_stamp: Noizu.Entity.TimeStamp.now()
                           }
                           |> Noizu.Intellect.Entity.Repo.create(context),
         {:ok, channel_ref} <- Noizu.EntityReference.Protocol.ref(channel)
      do
      %Noizu.Intellect.Schema.Account.Channel.Member{
        channel: channel_ref,
        member: agent_ref,
        created_on: current_time,
        modified_on: current_time
      } |> Noizu.Intellect.Repo.insert() |> IO.inspect()

      %Noizu.Intellect.Account.Agent.Chat.Session{
        agent: agent_ref,
        member: socket.assigns[:active_member_ref],
        channel: channel_ref,
        #details: %{title: "Chat Session", body: "Chat Session"},
        time_stamp: Noizu.Entity.TimeStamp.now()
      }
      |> Noizu.Intellect.Entity.Repo.create(context)

      js = hide_modal("#{modal}")
      socket = socket
               |> assign(active_channel: channel)
               |> assign(active_channel_ref: channel_ref)
               |> assign(view: :session)
               |> push_event("js_push", %{js: js.ops})

      Noizu.Intellect.Service.Agent.Ingestion.fetch({agent_ref, channel_ref}, :state, context) |> IO.inspect()

      channel_switch(channel, socket)
    else
      error ->
        {:noreply, socket}
    end
  end

  def channel_switch(channel, socket) do
    context = socket.assigns[:context]
    with {:ok, channel_ref} <- Noizu.EntityReference.Protocol.ref(channel),
         {:ok, channel_sref} <- Noizu.EntityReference.Protocol.sref(channel),
         {:ok, messages} <- Noizu.IntellectApi.Messages.recent(channel_ref, context, limit: 250)
      do


      Noizu.Intellect.LiveEventModule.unsubscribe(event(subject: "chat", instance: socket.assigns[:active_channel_sref], event: "sent"))

      socket = socket
               |> assign(active_channel: channel)
               |> assign(active_channel_ref: channel_ref)
               |> assign(active_channel_sref: channel_sref)


      Noizu.Intellect.LiveEventModule.subscribe(event(subject: "chat", instance: channel_sref, event: "sent"))
      messages = messages
                 |> Noizu.Intellect.LiveView.Encoder.encode!(context)
                 |> Enum.reverse()
      socket = socket
               |> assign(messages: messages)
               |> assign(error: nil)


      {:noreply, socket}
    else
      _ -> {:noreply, socket}
    end
  end

  def edit_channel(channel, params, socket) do
    with {:ok, channel} <- put_in(channel, [Access.key(:details), Access.key(:title)], params["title"])
                           |> Noizu.Intellect.Entity.Repo.update(socket.assigns[:context]) do

      js = hide_modal(params["modal"])

      socket = socket
               |> assign(:active_channel, channel)
               |> push_event("js_push", %{js: js.ops})

      {:noreply, socket}
    else
      _ -> {:noreply, socket}
    end
  end

  #===========================
  #
  #===========================
  def handle_event("create:session", %{"agent" => agent} = params, socket) do
    IO.puts "CREATE SESSION"
    create_chat_session(String.to_integer(agent), params["modal"], socket)
  end

  def handle_event("show:session", params, socket) do
    switch_to_session(params["session"]  |> String.to_integer(), params["modal"], socket)
  end

  def handle_event("channel:switch", %{"channel" => channel}, socket) do
    with {:ok, channel} <- Noizu.Intellect.Account.channel_by_slug(socket.assigns[:active_project], channel, socket.assigns[:context]) do
      channel_switch(channel, socket)
    else
      _ -> {:noreply, socket}
    end
  end


  def handle_event("edit:channel", %{"channel" => channel} = params, socket) do
    with {:ok, channel} <- Noizu.Intellect.Account.Channel.entity(String.to_integer(channel), socket.assigns[:context]) do
      edit_channel(channel, params, socket)
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event(event, params, socket) do
    IO.puts """
    uncaught #{__MODULE__}.handle_event
      event: #{inspect event}
      params: #{inspect params}
    """
    {:noreply, socket}
  end



  #===========================
  #
  #===========================
#  def handle_info(info = event(subject: "chat", instance: _channel_sref, event: "typing", payload: message, options: options), socket) do
#    socket = socket
#             |> assign(messages: socket.assigns[:messages] ++ [message])
#    {:noreply, socket}
#  end
  def handle_info(_info = event(subject: "chat", instance: _channel_sref, event: "sent", payload: message, options: options), socket) do
    messages = socket.assigns[:messages] ++ [message]
    socket = socket
             |> assign(messages: messages)
             |> then(
                  fn(socket) ->
                    cond do
                      options[:scroll] ->
                        js = JS.dispatch("scroll:bottom", to: "html")
                             socket
                             |> push_event("js_push", %{js: js.ops})
                      :else -> socket
                    end
                  end)
    {:noreply, socket}
  end


  #===========================
  #
  #===========================
  def update(assigns, socket) do
    IO.puts "UPDATE? #{inspect assigns}"
    {:ok, socket}
  end

  def mount(_, session, socket) do
    context = session["context"]

    (with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(session["active_channel"]),
          {:ok, active_project_ref} <- Noizu.EntityReference.Protocol.ref(session["active_project"]),
          {:ok, active_channel_ref} <- Noizu.EntityReference.Protocol.ref(session["active_channel"]),
          {:ok, active_member_ref} <- Noizu.EntityReference.Protocol.ref(session["active_member"]),
          {:ok, messages} <- Noizu.IntellectApi.Messages.recent(active_channel_ref, context, limit: 250)
       do
       Noizu.Intellect.LiveEventModule.subscribe(event(subject: "chat", instance: sref, event: "sent"))
       messages = messages
                  |> Noizu.Intellect.LiveView.Encoder.encode!(context)
                  |> Enum.reverse()

#       error = try do
#         raise ArgumentError, "Example Error Raise"
#         rescue e ->
#           %Noizu.IntellectWeb.LiveViewError{
#              title: Noizu.IntellectWeb.Gettext.gettext("Argument Error"),
#              body: Noizu.IntellectWeb.Gettext.gettext("Demo of Error Functionality"),
#              error: e,
#              trace: __STACKTRACE__,
#              time_stamp: DateTime.utc_now(),
#              context: context
#           }
#       end
       socket = with {:ok, agents} <- Noizu.IntellectApi.Agents.by_project(session["active_project"], context) do
         socket
         |> assign(agents: agents)
       else
         _ ->
           # Error
           socket
           |> assign(agents: [])
       end
                |> assign(active_project_ref: active_project_ref)
                |> assign(active_channel_ref: active_channel_ref)
                |> assign(active_channel_sref: sref)
                |> assign(active_member_ref: active_member_ref)
                |> assign(mood: session["mood"])
                |> assign(active_user: session["active_user"])
                |> assign(active_project: session["active_project"])
                |> assign(active_channel: session["active_channel"])
                |> assign(active_member: session["active_member"])
                |> assign(messages: messages)
                |> assign(context: context)
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
