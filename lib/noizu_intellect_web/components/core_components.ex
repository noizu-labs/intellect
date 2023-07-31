defmodule Noizu.IntellectWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At the first glance, this module may seem daunting, but its goal is
  to provide some core building blocks in your application, such modals,
  tables, and forms. The components are mostly markup and well documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import Noizu.IntellectWeb.Gettext



  # from https://github.com/phoenixframework/phoenix_live_view/pull/2004/files
  def toggle_attribute({attr, val}), do: toggle_attribute(%JS{}, {attr, val}, [])

  @doc "See `toggle_attribute/1`."
  def toggle_attribute({attr, val}, opts) when is_list(opts),
      do: toggle_attribute(%Phoenix.LiveView.JS{}, {attr, val}, opts)

  def toggle_attribute(%Phoenix.LiveView.JS{} = js, {attr, val}), do: toggle_attribute(js, {attr, val}, [])

  @doc "See `toggle_attribute/1`."
  def toggle_attribute(%Phoenix.LiveView.JS{} = js, {attr, val}, opts) when is_list(opts) do
    opts = validate_keys(opts, :toggle_attribute, [:to])
    put_op(js, "toggle_attr", %{to: opts[:to], attr: [attr, val]})
  end

  def put_op(%Phoenix.LiveView.JS{ops: ops} = js, kind, args) do
    %Phoenix.LiveView.JS{js | ops: ops ++ [[kind, args]]}
  end

  def validate_keys(opts, kind, allowed_keys) do
    for key <- Keyword.keys(opts) do
      if key not in allowed_keys do
        raise ArgumentError, """
        invalid option for #{kind}
        Expected keys to be one of #{inspect(allowed_keys)}, got: #{inspect(key)}
        """
      end
    end

    opts
  end

  def image_service(:profile, image, _options \\ nil) do
    # todo use cdn
    "/documents/v1.0/image/profile/#{image || "default"}?format=standard"
  end

  attr :mood, :string, default: nil
  def mood_label(assigns) do
    ~H"""
    <%= cond do %>
      <% @mood == :excited -> %>
      Excited
      <% @mood == :loved -> %>
      Loved
      <% @mood == :happy -> %>
      Happy
      <% @mood == :sad -> %>
      Sad
      <% @mood == :thumbsy -> %>
      Thumbsy
      <% @mood == :nothing -> %>
      I feel nothing
      <% :else -> %>
    <% end %>
    """
  end

  attr :mood, :string, default: nil
  attr :size, :atom, default: :normal
  def mood_glyph(assigns) do
    ~H"""
    <%= if @size == :normal do %>
      <%= cond do %>
        <% @mood == :excited -> %>
          <span class="bg-red-500 flex h-8 w-8 items-center justify-center rounded-full">
              <svg class="text-white h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path fill-rule="evenodd" d="M13.5 4.938a7 7 0 11-9.006 1.737c.202-.257.59-.218.793.039.278.352.594.672.943.954.332.269.786-.049.773-.476a5.977 5.977 0 01.572-2.759 6.026 6.026 0 012.486-2.665c.247-.14.55-.016.677.238A6.967 6.967 0 0013.5 4.938zM14 12a4 4 0 01-4 4c-1.913 0-3.52-1.398-3.91-3.182-.093-.429.44-.643.814-.413a4.043 4.043 0 001.601.564c.303.038.531-.24.51-.544a5.975 5.975 0 011.315-4.192.447.447 0 01.431-.16A4.001 4.001 0 0114 12z" clip-rule="evenodd" />
              </svg>
          </span>
        <% @mood == :loved -> %>
          <span class="bg-pink-400 flex h-8 w-8 items-center justify-center rounded-full">
              <svg class="text-white h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path d="M9.653 16.915l-.005-.003-.019-.01a20.759 20.759 0 01-1.162-.682 22.045 22.045 0 01-2.582-1.9C4.045 12.733 2 10.352 2 7.5a4.5 4.5 0 018-2.828A4.5 4.5 0 0118 7.5c0 2.852-2.044 5.233-3.885 6.82a22.049 22.049 0 01-3.744 2.582l-.019.01-.005.003h-.002a.739.739 0 01-.69.001l-.002-.001z" />
              </svg>
          </span>
        <% @mood == :happy -> %>
          <span class="bg-green-400 flex h-8 w-8 items-center justify-center rounded-full">
              <svg class="text-white h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.536-4.464a.75.75 0 10-1.061-1.061 3.5 3.5 0 01-4.95 0 .75.75 0 00-1.06 1.06 5 5 0 007.07 0zM9 8.5c0 .828-.448 1.5-1 1.5s-1-.672-1-1.5S7.448 7 8 7s1 .672 1 1.5zm3 1.5c.552 0 1-.672 1-1.5S12.552 7 12 7s-1 .672-1 1.5.448 1.5 1 1.5z" clip-rule="evenodd" />
              </svg>
          </span>
        <% @mood == :sad -> %>
          <span class="bg-yellow-400 flex h-8 w-8 items-center justify-center rounded-full">
              <svg class="text-white h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm-3.536-3.475a.75.75 0 001.061 0 3.5 3.5 0 014.95 0 .75.75 0 101.06-1.06 5 5 0 00-7.07 0 .75.75 0 000 1.06zM9 8.5c0 .828-.448 1.5-1 1.5s-1-.672-1-1.5S7.448 7 8 7s1 .672 1 1.5zm3 1.5c.552 0 1-.672 1-1.5S12.552 7 12 7s-1 .672-1 1.5.448 1.5 1 1.5z" clip-rule="evenodd" />
              </svg>
          </span>
        <% @mood == :thumbsy ->  %>
          <span class="bg-blue-500 flex h-8 w-8 items-center justify-center rounded-full">
              <svg class="text-white h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path d="M1 8.25a1.25 1.25 0 112.5 0v7.5a1.25 1.25 0 11-2.5 0v-7.5zM11 3V1.7c0-.268.14-.526.395-.607A2 2 0 0114 3c0 .995-.182 1.948-.514 2.826-.204.54.166 1.174.744 1.174h2.52c1.243 0 2.261 1.01 2.146 2.247a23.864 23.864 0 01-1.341 5.974C17.153 16.323 16.072 17 14.9 17h-3.192a3 3 0 01-1.341-.317l-2.734-1.366A3 3 0 006.292 15H5V8h.963c.685 0 1.258-.483 1.612-1.068a4.011 4.011 0 012.166-1.73c.432-.143.853-.386 1.011-.814.16-.432.248-.9.248-1.388z" />
              </svg>
          </span>
        <% @mood == :nothing -> %>
          <span class="bg-transparent flex h-8 w-8 items-center justify-center rounded-full">
              <svg class="text-gray-400 h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
              </svg>
          </span>
        <% :else -> %>
      <% end %>
    <% else %>
    <%= cond do %>
        <% @mood == :excited -> %>
          <span class="bg-red-500 flex h-4 w-4 items-center justify-center rounded-full">
              <svg class="text-white h-2 w-2 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path fill-rule="evenodd" d="M13.5 4.938a7 7 0 11-9.006 1.737c.202-.257.59-.218.793.039.278.352.594.672.943.954.332.269.786-.049.773-.476a5.977 5.977 0 01.572-2.759 6.026 6.026 0 012.486-2.665c.247-.14.55-.016.677.238A6.967 6.967 0 0013.5 4.938zM14 12a4 4 0 01-4 4c-1.913 0-3.52-1.398-3.91-3.182-.093-.429.44-.643.814-.413a4.043 4.043 0 001.601.564c.303.038.531-.24.51-.544a5.975 5.975 0 011.315-4.192.447.447 0 01.431-.16A4.001 4.001 0 0114 12z" clip-rule="evenodd" />
              </svg>
          </span>
        <% @mood == :loved -> %>
          <span class="bg-pink-400 flex h-4 w-4 items-center justify-center rounded-full">
              <svg class="text-white h-2 w-2 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path d="M9.653 16.915l-.005-.003-.019-.01a20.759 20.759 0 01-1.162-.682 22.045 22.045 0 01-2.582-1.9C4.045 12.733 2 10.352 2 7.5a4.5 4.5 0 018-2.828A4.5 4.5 0 0118 7.5c0 2.852-2.044 5.233-3.885 6.82a22.049 22.049 0 01-3.744 2.582l-.019.01-.005.003h-.002a.739.739 0 01-.69.001l-.002-.001z" />
              </svg>
          </span>
        <% @mood == :happy -> %>
          <span class="bg-green-400 flex h-4 w-4 items-center justify-center rounded-full">
              <svg class="text-white h-2 w-2 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.536-4.464a.75.75 0 10-1.061-1.061 3.5 3.5 0 01-4.95 0 .75.75 0 00-1.06 1.06 5 5 0 007.07 0zM9 8.5c0 .828-.448 1.5-1 1.5s-1-.672-1-1.5S7.448 7 8 7s1 .672 1 1.5zm3 1.5c.552 0 1-.672 1-1.5S12.552 7 12 7s-1 .672-1 1.5.448 1.5 1 1.5z" clip-rule="evenodd" />
              </svg>
          </span>
        <% @mood == :sad -> %>
          <span class="bg-yellow-400 flex h-4 w-4 items-center justify-center rounded-full">
              <svg class="text-white h-2 w-2 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm-3.536-3.475a.75.75 0 001.061 0 3.5 3.5 0 014.95 0 .75.75 0 101.06-1.06 5 5 0 00-7.07 0 .75.75 0 000 1.06zM9 8.5c0 .828-.448 1.5-1 1.5s-1-.672-1-1.5S7.448 7 8 7s1 .672 1 1.5zm3 1.5c.552 0 1-.672 1-1.5S12.552 7 12 7s-1 .672-1 1.5.448 1.5 1 1.5z" clip-rule="evenodd" />
              </svg>
          </span>
        <% @mood == :thumbsy ->  %>
          <span class="bg-blue-500 flex h-4 w-4 items-center justify-center rounded-full">
              <svg class="text-white h-2 w-2 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path d="M1 8.25a1.25 1.25 0 112.5 0v7.5a1.25 1.25 0 11-2.5 0v-7.5zM11 3V1.7c0-.268.14-.526.395-.607A2 2 0 0114 3c0 .995-.182 1.948-.514 2.826-.204.54.166 1.174.744 1.174h2.52c1.243 0 2.261 1.01 2.146 2.247a23.864 23.864 0 01-1.341 5.974C17.153 16.323 16.072 17 14.9 17h-3.192a3 3 0 01-1.341-.317l-2.734-1.366A3 3 0 006.292 15H5V8h.963c.685 0 1.258-.483 1.612-1.068a4.011 4.011 0 012.166-1.73c.432-.143.853-.386 1.011-.814.16-.432.248-.9.248-1.388z" />
              </svg>
          </span>
        <% @mood == :nothing -> %>
          <span class="bg-transparent flex h-4 w-4 items-center justify-center rounded-full">
              <svg class="text-gray-400 h-2 w-2 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
              </svg>
          </span>
        <% :else -> %>
      <% end %>
    <% end %>
    """
  end

  attr :id, :string, required: true
  attr :error, Noizu.IntellectWeb.LiveViewError, required: true
  attr :context, :any, default: nil
  def display_error(assigns) do
  ~H"""
  <div class="bg-white px-4 py-5 sm:px-6">
    <div class="flex flex-col space-y-3 justify-start">
      <div class="flex flex-row space-x-3">
        <div class="flex-shrink-0">
          <div class={"alert glyph #{@error.severity || :other}-alert"}>
              <%= cond do %>
                <% @error.severity in [:warning, :error, :info] -> %>
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
                  </svg>
              <% @error.severity in [:success] -> %>
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                  </svg>
              <% :else -> %>
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9.879 7.519c1.171-1.025 3.071-1.025 4.242 0 1.172 1.025 1.172 2.687 0 3.712-.203.179-.43.326-.67.442-.745.361-1.45.999-1.45 1.827v.75M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9 5.25h.008v.008H12v-.008z" />
                  </svg>
              <% end %>
          </div>
        </div>
        <div class="min-w-0 flex-1">
          <p class="text-sm font-semibold text-gray-900">
            <a href="#" class="hover:underline"><%= @error.title %></a>
          </p>
          <p class="text-sm text-gray-500">
            <a href="#" class="hover:underline"><.elapsedTime since={@error.time_stamp || DateTime.utc_now()}/></a>
          </p>
        </div>
      </div>

      <div class="flex flex-shrink-0 self-start">
        <pre>
        <%= @error.raw && Phoenix.HTML.raw(@error.body) || @error.body %>
        </pre>
      </div>

      <%= if Noizu.IntellectWeb.LiveViewError.show_details(@error, @context) do %>
        <h2 class="prose prose-xl">Error</h2>
        <div class="flex flex-shrink-0 self-start">
          <pre class="scroll overflow-scroll">
          <%= case @error.error do %>
            <% v when is_tuple(v) -> %>
              <%= "#{inspect(@error.error)}" %>
            <% _ -> %>
<%= Exception.format(@error.kind, @error.error, @error.trace)  %>
          <% end %>
          </pre>
        </div>
      <% end %>


      <%= if Noizu.IntellectWeb.LiveViewError.show_trace(@error, @context) do %>
        <h2 class="prose prose-xl">Trace</h2>
        <div class="flex flex-shrink-0 self-start overflow-auto">
          <pre class="scroll overflow-scroll"><%= @error.trace |> Enum.map(&("#{inspect &1}")) |> Enum.join("\n") %></pre>
        </div>
      <% end %>


    </div>
  </div>


  """
  end


  attr :id, :string, required: true
  attr :target, :any, required: true
  attr :mood_selector, :any, default: %{selected: nil}
  attr :expanding, :boolean, default: true
  attr :placeholder, :string, default: "Add your message..."
  attr :phx_submit, :any, default: "message:submit"
  def message_input(assigns) do
  ~H"""
  <div class="relative bottom-0 left-0 w-full h-48 ">
  <form id={@id} action="#" class="relative w-full h-full bottom-0 left-0 right-0" phx-submit={@phx_submit} phx-target={@target}>
            <div class="w-full h-fit">
                <div
                    class="overflow-hidden
                        nz-massage-input-box
                        bg-slate-200 rounded-lg min-h-24 text-black
                        absolute bottom-0 w-full
                        opacity-90
                        focus-within:opacity-100
                        p-4 pb-12 shadow-lg shadow-black focus-within:ring-gray-500 ring-gray-400 ring-1"
                    >
                    <label for={"#{@id}-comment"} class="sr-only">Add your message.</label>
                    <%= if @expanding do %>
                      <textarea
                        phx-hook="ExpandingTextArea"
                        name="comment"
                        id={"#{@id}-comment"}
                        phx-update="ignore"
                        class="
                              resize-none
                              block

                              w-full
                              min-h-46
                              max-h-96
                              overflow-y-auto
                              mx-auto
                              focus:outline-none
                              border-0 bg-transparent py-1.5 text-black placeholder:text-gray-400 focus:ring-0 sm:text-sm sm:leading-6
                        "
                        placeholder="Add your message..."
                      ></textarea>
                    <% else %>
                      <textarea
                        name="comment"
                        id={"#{@id}-comment"}
                        phx-update="ignore"
                        class="
                              resize-none
                              bottom-0
                              block
                              w-full
                              min-h-16
                              max-h-[30vh]
                              overflow-y-auto
                              mx-auto
                              focus:outline-none
                              border-0 bg-transparent py-1.5 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm sm:leading-6
                        "
                        placeholder="Add your message..."
                      ></textarea>
                    <% end %>
                </div>
            </div>



            <input type="hidden" name="current-mood" value={@mood_selector.selected}/>
            <div class="absolute nz-massage-input-box inset-x-0 bottom-0 flex justify-between py-2 pl-3 pr-2">
                <div class="flex items-center space-x-5">
                    <div class="flex items-center">
                        <button type="button" class="-m-2.5 flex h-10 w-10 items-center justify-center rounded-full text-gray-700 hover:text-gray-800">
                            <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                                <path fill-rule="evenodd" d="M15.621 4.379a3 3 0 00-4.242 0l-7 7a3 3 0 004.241 4.243h.001l.497-.5a.75.75 0 011.064 1.057l-.498.501-.002.002a4.5 4.5 0 01-6.364-6.364l7-7a4.5 4.5 0 016.368 6.36l-3.455 3.553A2.625 2.625 0 119.52 9.52l3.45-3.451a.75.75 0 111.061 1.06l-3.45 3.451a1.125 1.125 0 001.587 1.595l3.454-3.553a3 3 0 000-4.242z" clip-rule="evenodd" />
                            </svg>
                            <span class="sr-only">Attach a file</span>
                        </button>
                    </div>
                    <.mood_selector id={"#{@id}-select-mood"} target={@target} mood={@mood_selector} />
                </div>
                <button type="submit" class="rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">Comment</button>
            </div>

        </form>
  </div>
  """
  end


  attr :id, :string, required: true
  attr :title, :string, default: ""
  attr :show, :boolean, default: false
  attr :on_collapse, JS, default: %JS{}
  attr :background, :string, default: "bg-slate-500"
  slot :inner_block, required: true
  def sidebar(assigns) do
    ~H"""
    <div
      id={@id}
      phx-remove={JS.set_attribute({"aria-expanded", "false"})}
      data-collapse={JS.exec(@on_collapse, "phx-remove")}
      class="sidebar flex flex-row justify-end"
      aria-labelledby="slide-over-title"
      role="dialog"
      aria-expanded={@show && "true" || "false"}>
        <!-- Background backdrop, show/hide based on slide-over state. -->
        <%= if @background do %>
          <div class={"sidebar-bg #{@background}"}></div>
        <% end %>

        <div class="sidebar-pull close">
          <div class="fixed ml-3 z-20 top-[50%]">
            <div
              phx-click={JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")}
              class="sidebar-pull-anchor">

            </div>
          </div>
        </div>
        <div
          id={"#{@id}-pull"}
          class="sidebar-pull open"
        >
          <div class="fixed ml-3 z-20 top-[50%]">
            <div
              phx-click={JS.set_attribute({"aria-expanded", "true"}, to: "##{@id}")}
              class="sidebar-pull-anchor">

            </div>
          </div>
        </div>

        <div
          id={"#{@id}-aside"}
          class="sidebar-aside"
          phx-click-away={JS.exec("data-collapse", to: "##{@id}")}
          phx-click={JS.set_attribute({"aria-expanded", "true"}, to: "##{@id}")}
        >


            <div class="mt-6 flex-1 px-4 sm:px-6 z-20">
                    <%= render_slot(@inner_block) %>
            </div>

        </div>

    </div>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :show, :boolean, default: false
  attr :target, :any, required: true
  attr :on_cancel, JS, default: %JS{}
  def mood_selector(assigns) do
    ~H"""
    <div
      id={@id}
      class="noizu-chat-mood-selector flex items-center"
      phx-remove={JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}-toggle")}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
    >
    <div>
      <label id="listbox-label" class="sr-only">Your mood</label>
      <div class="relative">
        <button
                id={"#{@id}-toggle"}
                phx-click={JS.set_attribute({"aria-expanded", "true"})}
                type="button"
                class="
                  relative -m-2.5 flex h-10 w-10
                  items-center justify-center
                  rounded-full
                  text-gray-600 hover:text-gray-700
                  focus:outline-none
                "
                aria-haspopup="listbox"
                aria-expanded="false"
                aria-labelledby="listbox-label"
        >
                  <span class="flex items-center justify-center">
                    <!-- Placeholder label, show/hide based on listbox state. -->
                    <%= if @mood.selected && @mood.selected != :nothing do %>
                      <span class="noizu-chat-input-current-mood">
                        <span class="flex items-center">
                          <.mood_glyph mood={@mood.selected} />
                          <span class="sr-only"><.mood_label mood={@mood.selected} /></span>
                        </span>
                      </span>
                  <% else %>
                    <span class="noizu-chat-input-show-select-mood">
                      <svg class="h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.536-4.464a.75.75 0 10-1.061-1.061 3.5 3.5 0 01-4.95 0 .75.75 0 00-1.06 1.06 5 5 0 007.07 0zM9 8.5c0 .828-.448 1.5-1 1.5s-1-.672-1-1.5S7.448 7 8 7s1 .672 1 1.5zm3 1.5c.552 0 1-.672 1-1.5S12.552 7 12 7s-1 .672-1 1.5.448 1.5 1 1.5z" clip-rule="evenodd" />
                      </svg>
                      <span class="sr-only">Add your mood</span>
                    </span>
                    <% end %>
                  </span>
        </button>
        <div class="noizu-chat-input-bg bg-none fixed inset-0 transition-opacity" aria-hidden="true" />
        <ul
          id={"#{@id}-menu"}
          class="noizu-chat-input-select-mood absolute bottom-10 z-10 -ml-6 w-60 rounded-lg bg-white py-3 text-base shadow ring-1 ring-black ring-opacity-5 focus:outline-none sm:ml-auto sm:w-64 sm:text-sm" tabindex="-1" role="listbox" aria-labelledby="listbox-label" aria-activedescendant="listbox-option-5"
          phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
          phx-key="escape"
          phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
        >
          <%= for for_mood <- [:excited, :loved, :happy, :sad, :thumbsy, :nothing] do %>
            <li phx-click="set-mood" phx-target={@target} phx-value-id={@id} phx-value-mood={for_mood} class="bg-white hover:bg-gray-100  relative cursor-default select-none px-3 py-2" id="listbox-option-0" role="option">
              <div class="flex items-center">
                <.mood_glyph mood={for_mood} />
                <span class="ml-3 block truncate font-medium"><.mood_label mood={for_mood} /></span>
              </div>
            </li>
          <% end %>

        </ul>
      </div>
    </div>
    </div>
    """
  end


  attr :since, DateTime
  def elapsedTime(assigns) do
    ~H"""
    <time datetime={DateTime.to_iso8601(@since)} class="nz-elapsed-time flex-none py-0.5 text-xs leading-5 text-gray-500">
    <%= cond do %>
    <% DateTime.diff(DateTime.utc_now(), @since) >= (3600 * 24 * 365) -> %>
    <%= div(DateTime.diff(DateTime.utc_now(), @since), (3600 * 24 * 365)) %>y ago
    <% DateTime.diff(DateTime.utc_now(), @since) >= (3600 * 24) -> %>
    <%= div(DateTime.diff(DateTime.utc_now(), @since), (3600 * 24)) %>d ago
    <% DateTime.diff(DateTime.utc_now(), @since) >= 3600 -> %>
    <%= div(DateTime.diff(DateTime.utc_now(), @since), 3600) %>h ago
    <% DateTime.diff(DateTime.utc_now(), @since) >= 60 -> %>
    <%= div(DateTime.diff(DateTime.utc_now(), @since), 60) %>m ago
    <% DateTime.diff(DateTime.utc_now(), @since) >= 10 -> %>
    <%= DateTime.diff(DateTime.utc_now(), @since) %>s ago
    <% :else -> %>
    just now
    <% end %>
    </time>
    """
  end


  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :align, :string, default: ""
  attr :class, :string, default: "w-screen max-w-md flex-auto overflow-hidden rounded-3xl bg-white text-sm leading-6 shadow-lg ring-1 ring-gray-900/5"
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true
  def flyout_menu(assigns) do
    ~H"""
    <div
      id={@id}
      class="relative nz-flyout"
      phx-remove={JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}-menu")}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
    >
      <button
        id={"#{@id}-menu"}
        phx-click={JS.set_attribute({"aria-expanded", "true"})}
        type="button"
        class="
          focus:outline-none
          inline-flex items-center
          gap-x-1
          text-sm font-semibold leading-6 text-gray-900
        "
        aria-expanded="false"
        disabled-phx-hook="AriaExpandedToggle" data-phx-hook-focus={"#{@id} .nz-flyout-body"}
      >
      <span><%= @title %></span>
      <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
        <path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clip-rule="evenodd" />
      </svg>
      </button>
      <div class="nz-flyout-bg bg-none fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class={"nz-flyout-body fixed z-20 right-0 w-screen max-w-max  mt-2 flex px-4 #{@align}"}
      >
        <div
        id={"#{@id}-container"}
        phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
        phx-key="escape"
        phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
        class={@class}
      >
              <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>


    """
  end


  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden modal"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title="Success!" flash={@flash} />
    <.flash kind={:error} title="Error!" flash={@flash} />
    <.flash
      id="disconnected"
      kind={:error}
      title="We can't find the internet"
      phx-disconnected={show("#disconnected")}
      phx-connected={hide("#disconnected")}
      hidden
    >
      Attempting to reconnect <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(autocomplete cols disabled form list max maxlength min minlength
                pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-1 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          "min-h-[6rem] border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pr-6 pb-4 font-normal"><%= col[:label] %></th>
            <th class="relative p-0 pb-4"><span class="sr-only"><%= gettext("Actions") %></span></th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500"><%= item.title %></dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Hero Icon](https://heroicons.com).

  Hero icons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid an mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(Noizu.IntellectWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(Noizu.IntellectWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
