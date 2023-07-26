defmodule Noizu.IntellectWeb.Nav.Tags do
  use Noizu.IntellectWeb, :component



  def modal_classes__mask(modal) do
    case modal.mask do
      :required -> ["required"]
      :mask -> ["mask"]
      _ -> []
    end
  end

  def modal_classes__open(modal) do
    if modal.enabled do
      ["open"]
    else
      []
    end
  end

  def modal_classes__theme(modal) do
    case modal.theme do
      :yellow -> ["modal-yellow-theme"]
      :red -> ["modal-red-theme"]
      :blue -> ["modal-blue-theme"]
      :green -> ["modal-green-theme"]
      "modal-" <> _ -> [modal.theme]
      _ -> []
    end
  end

  def modal_classes__size(modal) do
    case modal.size do
      :sm -> ["modal-sm"]
      :md -> ["modal-md"]
      :lg -> ["modal-lg"]
      :xl -> ["modal-xl"]
      "modal-" <> _ -> [modal.size]
      _ -> []
    end
  end

  def modal_container_classes(modal) do
    classes = ["modal-container"] ++
              modal_classes__open(modal) ++
              modal_classes__mask(modal) ++
              modal_classes__theme(modal) ++
              modal_classes__size(modal)
    Enum.join(classes, " ")
  end

  def modal_classes(modal) do
    base = ["modal"]
    top = (cond do
             modal.position[:top] -> [modal.position[:top]]
             :else -> []
           end)
    left = (cond do
             modal.position[:left] -> [modal.position[:left]]
             :else -> []
           end)
    right = (cond do
             modal.position[:right] -> [modal.position[:right]]
             :else -> []
           end)
    bottom = (cond do
             modal.position[:bottom] -> [modal.position[:bottom]]
             :else -> []
           end)
    classes = base ++ top ++ right ++ left ++ bottom
    Enum.join(classes, " ")
  end

  attr :id, :string
  attr :socket, :map, default: false
  attr :modal, :map, default: false
  def modal_queue_entry(assigns) do
    ~H"""
          <div :if={@modal.enabled} class={ modal_container_classes(@modal) }>
            <div class="modal-mask"></div>
            <div class={ modal_classes(@modal) } >
              <div class="modal-header"><%= @modal.title %></div>
              <div class="modal-body">
      <%= live_render(@socket, elem(@modal.widget, 0), id: elem(@modal.widget, 1), session: elem(@modal.widget, 2)) %>
              </div>
            </div>
          </div>
    """
  end



  defp flash__color(:error), do: "bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative"
  attr :"error-title", :string, default: "An Error"
  attr :"error-body", :string, default: "Has Occurred"
  attr :level, :atom, default: :error
  def noizu_alert(assigns) do
    ~H"""
    <div class="mb-4 items-center">
      <div class={flash__color(@level)} role="alert">
        <strong class="font-bold"><%= assigns[:"error-title"] %></strong>
        <span class="block sm:inline"><%= assigns[:"error-body"] %></span>
        <span class="absolute top-0 bottom-0 right-0 px-4 py-3">
          <svg class="fill-current h-6 w-6 text-red-500" role="button" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20"><title>Close</title><path d="M14.348 14.849a1.2 1.2 0 0 1-1.697 0L10 11.819l-2.651 3.029a1.2 1.2 0 1 1-1.697-1.697l2.758-3.15-2.759-3.152a1.2 1.2 0 1 1 1.697-1.697L10 8.183l2.651-3.031a1.2 1.2 0 1 1 1.697 1.697l-2.758 3.152 2.758 3.15a1.2 1.2 0 0 1 0 1.698z"/></svg>
        </span>
      </div>
    </div>
    """
  end

  attr :"active-user", :map, default: nil
  def account_action(assigns) do
    ~H"""
    <.link navigate={assigns[:"active-user"] && "/logout" || "/login"} class="block py-2 pl-3 pr-4 text-gray-700 rounded hover:bg-gray-100 md:hover:bg-transparent md:border-0 md:hover:text-blue-700 md:p-0 dark:text-gray-400 md:dark:hover:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent">
      <%= assigns[:"active-user"] && "Logout" || "Login" %>
    </.link>
    """
  end

  attr :name, :string, default: "Noizu Intellect"
  def logo(assigns) do
    ~H"""
    <svg class="w-10 h-10 p-2 mr-3 text-black rounded-full bg-primary" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24">
      <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"></path>
    </svg>
    <span class="self-center text-xl font-semibold whitespace-nowrap text-black">
    <%= @name %>
    </span>
    """
  end






  def sidebar(assigns) do
      ~H"""
      <div class="hidden lg:fixed lg:inset-y-0 lg:left-0 lg:z-50 lg:block lg:w-20 lg:overflow-y-auto lg:bg-gray-900 lg:pb-4">
      <div class="flex h-16 shrink-0 items-center justify-center">
        <img class="h-8 w-auto" src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=500" alt="Your Company">
      </div>
      <nav class="mt-8">
        <ul role="list" class="flex flex-col items-center space-y-1">
          <li>
            <!-- Current: "bg-gray-800 text-white", Default: "text-gray-400 hover:text-white hover:bg-gray-800" -->
            <a href="#" class="bg-gray-800 text-white group flex gap-x-3 rounded-md p-3 text-sm leading-6 font-semibold">
              <svg class="h-6 w-6 shrink-0" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25" />
              </svg>
              <span class="sr-only">Dashboard</span>
            </a>
          </li>
          <li>
            <a href="#" class="text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-3 text-sm leading-6 font-semibold">
              <svg class="h-6 w-6 shrink-0" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
              </svg>
              <span class="sr-only">Team</span>
            </a>
          </li>
          <li>
            <a href="#" class="text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-3 text-sm leading-6 font-semibold">
              <svg class="h-6 w-6 shrink-0" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z" />
              </svg>
              <span class="sr-only">Projects</span>
            </a>
          </li>
          <li>
            <a href="#" class="text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-3 text-sm leading-6 font-semibold">
              <svg class="h-6 w-6 shrink-0" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5" />
              </svg>
              <span class="sr-only">Calendar</span>
            </a>
          </li>
          <li>
            <a href="#" class="text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-3 text-sm leading-6 font-semibold">
              <svg class="h-6 w-6 shrink-0" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 17.25v3.375c0 .621-.504 1.125-1.125 1.125h-9.75a1.125 1.125 0 01-1.125-1.125V7.875c0-.621.504-1.125 1.125-1.125H6.75a9.06 9.06 0 011.5.124m7.5 10.376h3.375c.621 0 1.125-.504 1.125-1.125V11.25c0-4.46-3.243-8.161-7.5-8.876a9.06 9.06 0 00-1.5-.124H9.375c-.621 0-1.125.504-1.125 1.125v3.5m7.5 10.375H9.375a1.125 1.125 0 01-1.125-1.125v-9.25m12 6.625v-1.875a3.375 3.375 0 00-3.375-3.375h-1.5a1.125 1.125 0 01-1.125-1.125v-1.5a3.375 3.375 0 00-3.375-3.375H9.75" />
              </svg>
              <span class="sr-only">Documents</span>
            </a>
          </li>
          <li>
            <a href="#" class="text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-3 text-sm leading-6 font-semibold">
              <svg class="h-6 w-6 shrink-0" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 6a7.5 7.5 0 107.5 7.5h-7.5V6z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 10.5H21A7.5 7.5 0 0013.5 3v7.5z" />
              </svg>
              <span class="sr-only">Reports</span>
            </a>
          </li>
        </ul>
      </nav>
      </div>
      """
  end


  slot :logo
  slot :link, default: [%{__slot__: :link, inner_block: nil, label: "Home", to: "/home"}]
  attr :"active-user", :map, default: nil
  def navbar(assigns) do
    ~H"""
    <nav class="h-fit w-full border-gray-600 px-1 bg-gray-400 z-90">
      <div class="flex flex-wrap items-center justify-between md:justify-start md:pl-20 md:pr-0 mx-auto z-nav">
        <%= render_slot(@logo) %>
        <button phx-click={toggle_dropdown(".navbar-default")} type="button" class="inline-flex items-center p-2 ml-3  mr-6 text-sm text-gray-500 rounded-lg md:hidden hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200 dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-600 z-nav" aria-controls="navbar-default" aria-expanded="false">
          <span class="sr-only">Open main menu</span>
          <svg class="w-6 h-6" aria-hidden="true" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" clip-rule="evenodd"></path></svg>
        </button>
        <div class="navbar-default hidden justify-end place-content-end w-full md:block md:w-4/6" id="navbar-default">
          <ul class="
          flex flex-col
          place-content-end
          justify-end
          pr-10 p-4 mt-4 border border-gray-100 rounded-lg bg-transparent
          md:flex-row md:space-x-2 md:mt-0 md:text-sm md:font-medium md:border-0 md:bg-white
          md:m-0 md:p-0 md:pr-5
          dark:bg-gray-800 dark:border-gray-700
          md:dark:bg-gray-900">
            <%= for link <- @link do %>
              <.link navigate={link.to} class="block py-0 pl-0 pr-0 text-gray-700
                                  bg-transparent  rounded
                                 hover:text-gray-500 justify-content-end
                            md:hover:bg-transparent md:border-0 md:hover:text-gray-700 md:p-0 md:py-3 md:px-0 md:m-0
                      dark:text-gray-400 md:dark:hover:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-gray-700">
                <%= link.label %>
              </.link>
            <% end %>
          </ul>
        </div>
        <div class="navbar-default hidden content-end w-full md:block md:w-1/6">
          <ul class="flex flex-col place-content-end p-4 mt-4 border border-gray-100 rounded-lg bg-transparent md:flex-row md:space-x-8 md:mt-0 md:text-sm md:font-medium md:border-0 md:bg-transparent dark:bg-gray-800 md:dark:bg-gray-900 dark:border-gray-700">
            <.account_action active-user={assigns[:"active-user"]} />
          </ul>
        </div>
      </div>
    </nav>
    """
  end




  defp toggle_dropdown(id, js \\ %JS{}) do
    js
    |> JS.toggle(to: id)
  end



end
