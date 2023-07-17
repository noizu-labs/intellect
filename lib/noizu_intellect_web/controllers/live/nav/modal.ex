defmodule Noizu.IntellectWeb.Nav.Modal do
  use Noizu.IntellectWeb, :live_view
  import Noizu.IntellectWeb.Nav.Tags
  require Logger
  require Noizu.Intellect.LiveEventModule
  Noizu.Intellect.LiveEventModule
  #alias  Phoenix.PubSub

  defmodule Definition do
    @type t :: %__MODULE__{
                 mask: :required | :mask | nil,
                 enabled: boolean,
                 identifier: any,
                 title: String.t,
                 widget: {atom, String.t, list},
                 theme: nil | String.t,
                 size: nil | String.t,
                 position: Map.t,
               }

    defstruct [
      mask: nil,
      enabled: false,
      identifier: nil,
      title: nil,
      widget: nil,
      theme: nil,
      size: nil,
      position: nil
    ]
  end



  def render(assigns) do
    ~H"""
      <div class={@open && "modals open" || "modals"}>
        <div class="modal-queue">
          <!-- fuzz background -->
          <div id="modal-queue-bg-blur" class="modal-queue-bg-layer"></div>
          <div id="modal-queue-bg-tint" class="modal-queue-bg-layer"></div>
          <!-- modals -->
          <div class="modal-queue-floor">
            <.modal_queue_entry
              :for={modal <- @modals}
               id={"modal-queue-#{modal.identifier}"}
               socket={@socket}
               modal={modal} />
          </div>
        </div>
      </div>

    """
  end


  def handle_info(
        Noizu.Intellect.LiveEventModule.event(
          subject: :modal,
          instance: instance,
          event: :launch, payload: modal) = _msg,
        socket) do

    if index = socket.assigns.modal_key[instance] do
      modals = socket.assigns.modals
      modals = put_in(modals, [Access.at(index), Access.key(:enabled)], true)
      socket = socket
               |> assign(open: true)
               |> assign(modals: modals)
      {:noreply, socket}
    else
      modals = socket.assigns.modals
      index = length(modals)
      modal_key = socket.assigns.modal_key
                  |> put_in([Access.key(modal.identifier)], index)

      Logger.error("START MODAL\n #{inspect modal, limit: :infinity}")

      modal = modal
              |> put_in([Access.key(:enabled)], true)
      modals = (modals ++ [modal])
      socket = socket
               |> assign(open: true)
               |> assign(modals: modals)
               |> assign(modal_key: modal_key)
      {:noreply, socket}
    end


  end



  def handle_info(
        Noizu.Intellect.LiveEventModule.event(
          subject: :modal,
          instance: instance,
          event: :close) = _msg,
        socket) do
    index = socket.assigns.modal_key[instance]
    socket = (if index do
                modals = socket.assigns.modals
                modals = put_in(modals, [Access.at(index), Access.key(:enabled)], false)
                open = Enum.find(modals, fn(m) -> m.enabled == true end) && true || false
                socket
                |> assign(open: open)
                |> assign(modals: modals)
              else
                socket
              end)
    {:noreply, socket}
  end

  def mount(_, _session, socket) do
    Noizu.Intellect.LiveEventModule.subscribe(
      Noizu.Intellect.LiveEventModule.event(subject: :modal, instance: nil, event: nil)
    )

    open = false
    modals = []
    modal_key = %{} # id -> index
    socket = socket
             |> assign(open: open)
             |> assign(modals: modals)
             |> assign(modal_key: modal_key)
    {:ok, socket}
  end
end
