defmodule Noizu.IntellectWeb.Chat.Mood do
  use Noizu.IntellectWeb, :live_component
  import Noizu.IntellectWeb.Nav.Tags



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
      <% :else %>
    <% end %>
    """
  end

  attr :mood, :string, default: nil
  def mood_glyph(assigns) do
    ~H"""
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
    """
  end

  def selector(assigns) do
  ~H"""
  <div id="noizu-chat-mood-selector" class="noizu-chat-mood-selector flex items-center" aria-expanded="false">
  <div>
    <label id="listbox-label" class="sr-only">Your mood</label>
    <div class="relative">
      <button
              type="button"
              class="
              relative -m-2.5 flex h-10 w-10
              items-center justify-center
              rounded-full
              text-gray-400 hover:text-gray-500
              focus:outline-none
              "
              aria-haspopup="listbox"
              aria-selected="false"
              aria-labelledby="listbox-label"
      >
                <span id="noizu-chat-input-toggle-select-mood" class="flex items-center justify-center" phx-hook="AriaEnableToggle" data-phx-hook-target="#noizu-chat-input-select-mood">
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

      <!--
        Select popover, show/hide based on select state.

        Entering: ""
          From: ""
          To: ""
        Leaving: "transition ease-in duration-100"
          From: "opacity-100"
          To: "opacity-0"
      -->
      <ul id="noizu-chat-input-select-mood" aria-selected="false" aria-enabled="false" phx-hook="AriaSelectToggle"  data-phx-hook-focus="#noizu-chat-input-toggle-select-mood"   class="noizu-chat-input-select-mood absolute bottom-10 z-10 -ml-6 w-60 rounded-lg bg-white py-3 text-base shadow ring-1 ring-black ring-opacity-5 focus:outline-none sm:ml-auto sm:w-64 sm:text-sm" tabindex="-1" role="listbox" aria-labelledby="listbox-label" aria-activedescendant="listbox-option-5">
        <!--
          Select option, manage highlight styles based on mouseenter/mouseleave and keyboard navigation.

          Highlighted: "bg-gray-100", Not Highlighted: "bg-white"
        -->
        <li phx-click="set-mood:excited" class="bg-white hover:bg-gray-100  relative cursor-default select-none px-3 py-2" id="listbox-option-0" role="option">
          <div class="flex items-center">
            <.mood_glyph mood={:excited} />
            <span class="ml-3 block truncate font-medium"><.mood_label mood={:excited} /></span>
          </div>
        </li>
        <li phx-click="set-mood:loved" class="bg-white hover:bg-gray-100 relative cursor-default select-none px-3 py-2" id="listbox-option-0" role="option">
          <div class="flex items-center">
            <.mood_glyph mood={:loved} />
            <span class="ml-3 block truncate font-medium"><.mood_label mood={:loved} /></span>
          </div>
        </li>
        <li phx-click="set-mood:happy" class="bg-white hover:bg-gray-100 relative cursor-default select-none px-3 py-2" id="listbox-option-0" role="option">
          <div class="flex items-center">
            <.mood_glyph mood={:happy} />
            <span class="ml-3 block truncate font-medium"><.mood_label mood={:happy} /></span>
          </div>
        </li>
        <li phx-click="set-mood:sad" class="bg-white hover:bg-gray-100 relative cursor-default select-none px-3 py-2" id="listbox-option-0" role="option">
          <div class="flex items-center">
            <.mood_glyph mood={:sad} />
            <span class="ml-3 block truncate font-medium"><.mood_label mood={:sad} /></span>
          </div>
        </li>
        <li phx-click="set-mood:thumbsy" class="bg-white hover:bg-gray-100 relative cursor-default select-none px-3 py-2" id="listbox-option-0" role="option">
          <div class="flex items-center">
            <.mood_glyph mood={:thumbsy} />
            <span class="ml-3 block truncate font-medium"><.mood_label mood={:thumbsy} /></span>
          </div>
        </li>
        <li phx-click="set-mood:nothing" class="bg-white hover:bg-gray-100 relative cursor-default select-none px-3 py-2" id="listbox-option-0" role="option">
          <div class="flex items-center">
            <.mood_glyph mood={:nothing} />
            <span class="ml-3 block truncate font-medium"><.mood_label mood={:nothing} /></span>
          </div>
        </li>

      </ul>
    </div>
  </div>
  </div>
  """
  end

end
