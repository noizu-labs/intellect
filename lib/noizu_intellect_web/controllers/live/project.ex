



defmodule Noizu.IntellectWeb.Project do
  use Noizu.IntellectWeb, :live_view

  def render2(assigns) do
    ~H"""
    <pre>
    User: <%= @active_user.name %>
    Created On: <%= @active_user.time_stamp.created_on %>
    Project: <%= @active_project.slug %>
    Channel: <%= @active_channel.slug %>
    </pre>


    <div class="bg-white p-2">

    <!--
    This example requires some changes to your config:

      ```
    // tailwind.config.js
    module.exports = {
    // ...
    plugins: [
      // ...
      require('@tailwindcss/forms'),
    ],
    }
    ```
    -->
    <ul role="list" class="space-y-6">
    <li class="relative flex gap-x-4">
    <div class="absolute left-0 top-0 flex w-6 justify-center -bottom-6">
      <div class="w-px bg-gray-200"></div>
    </div>
    <div class="relative flex h-6 w-6 flex-none items-center justify-center bg-white">
      <div class="h-1.5 w-1.5 rounded-full bg-gray-100 ring-1 ring-gray-300"></div>
    </div>
    <p class="flex-auto py-0.5 text-xs leading-5 text-gray-500"><span class="font-medium text-gray-900">Chelsea Hagon</span> created the invoice.</p>
    <time datetime="2023-01-23T10:32" class="flex-none py-0.5 text-xs leading-5 text-gray-500">7d ago</time>
    </li>
    <li class="relative flex gap-x-4">
    <div class="absolute left-0 top-0 flex w-6 justify-center -bottom-6">
      <div class="w-px bg-gray-200"></div>
    </div>
    <div class="relative flex h-6 w-6 flex-none items-center justify-center bg-white">
      <div class="h-1.5 w-1.5 rounded-full bg-gray-100 ring-1 ring-gray-300"></div>
    </div>
    <p class="flex-auto py-0.5 text-xs leading-5 text-gray-500"><span class="font-medium text-gray-900">Chelsea Hagon</span> edited the invoice.</p>
    <time datetime="2023-01-23T11:03" class="flex-none py-0.5 text-xs leading-5 text-gray-500">6d ago</time>
    </li>
    <li class="relative flex gap-x-4">
    <div class="absolute left-0 top-0 flex w-6 justify-center -bottom-6">
      <div class="w-px bg-gray-200"></div>
    </div>
    <div class="relative flex h-6 w-6 flex-none items-center justify-center bg-white">
      <div class="h-1.5 w-1.5 rounded-full bg-gray-100 ring-1 ring-gray-300"></div>
    </div>
    <p class="flex-auto py-0.5 text-xs leading-5 text-gray-500"><span class="font-medium text-gray-900">Chelsea Hagon</span> sent the invoice.</p>
    <time datetime="2023-01-23T11:24" class="flex-none py-0.5 text-xs leading-5 text-gray-500">6d ago</time>
    </li>
    <li class="relative flex gap-x-4">
    <div class="absolute left-0 top-0 flex w-6 justify-center -bottom-6">
      <div class="w-px bg-gray-200"></div>
    </div>
    <img src="https://images.unsplash.com/photo-1550525811-e5869dd03032?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" alt="" class="relative mt-3 h-6 w-6 flex-none rounded-full bg-gray-50">
    <div class="flex-auto rounded-md p-3 ring-1 ring-inset ring-gray-200">
      <div class="flex justify-between gap-x-4">
        <div class="py-0.5 text-xs leading-5 text-gray-500"><span class="font-medium text-gray-900">Chelsea Hagon</span> commented</div>
        <time datetime="2023-01-23T15:56" class="flex-none py-0.5 text-xs leading-5 text-gray-500">3d ago</time>
      </div>
      <p class="text-sm leading-6 text-gray-500">Called client, they reassured me the invoice would be paid by the 25th.</p>
    </div>
    </li>
    <li class="relative flex gap-x-4">
    <div class="absolute left-0 top-0 flex w-6 justify-center -bottom-6">
      <div class="w-px bg-gray-200"></div>
    </div>
    <div class="relative flex h-6 w-6 flex-none items-center justify-center bg-white">
      <div class="h-1.5 w-1.5 rounded-full bg-gray-100 ring-1 ring-gray-300"></div>
    </div>
    <p class="flex-auto py-0.5 text-xs leading-5 text-gray-500"><span class="font-medium text-gray-900">Alex Curren</span> viewed the invoice.</p>
    <time datetime="2023-01-24T09:12" class="flex-none py-0.5 text-xs leading-5 text-gray-500">2d ago</time>
    </li>
    <li class="relative flex gap-x-4">
    <div class="absolute left-0 top-0 flex w-6 justify-center h-6">
      <div class="w-px bg-gray-200"></div>
    </div>
    <div class="relative flex h-6 w-6 flex-none items-center justify-center bg-white">
      <svg class="h-6 w-6 text-indigo-600" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <path fill-rule="evenodd" d="M2.25 12c0-5.385 4.365-9.75 9.75-9.75s9.75 4.365 9.75 9.75-4.365 9.75-9.75 9.75S2.25 17.385 2.25 12zm13.36-1.814a.75.75 0 10-1.22-.872l-3.236 4.53L9.53 12.22a.75.75 0 00-1.06 1.06l2.25 2.25a.75.75 0 001.14-.094l3.75-5.25z" clip-rule="evenodd" />
      </svg>
    </div>
    <p class="flex-auto py-0.5 text-xs leading-5 text-gray-500"><span class="font-medium text-gray-900">Alex Curren</span> paid the invoice.</p>
    <time datetime="2023-01-24T09:20" class="flex-none py-0.5 text-xs leading-5 text-gray-500">1d ago</time>
    </li>
    </ul>

    <!-- New comment form -->
    <div class="mt-6 flex gap-x-3">
    <img src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" alt="" class="h-6 w-6 flex-none rounded-full bg-gray-50">
    <form action="#" class="relative flex-auto">
    <div class="overflow-hidden rounded-lg pb-12 shadow-sm ring-1 ring-inset ring-gray-300 focus-within:ring-2 focus-within:ring-indigo-600">
      <label for="comment" class="sr-only">Add your comment</label>
      <textarea rows="2" name="comment" id="comment" class="block w-full resize-none border-0 bg-transparent py-1.5 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm sm:leading-6" placeholder="Add your comment..."></textarea>
    </div>

    <div class="absolute inset-x-0 bottom-0 flex justify-between py-2 pl-3 pr-2">
      <div class="flex items-center space-x-5">
        <div class="flex items-center">
          <button type="button" class="-m-2.5 flex h-10 w-10 items-center justify-center rounded-full text-gray-400 hover:text-gray-500">
            <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M15.621 4.379a3 3 0 00-4.242 0l-7 7a3 3 0 004.241 4.243h.001l.497-.5a.75.75 0 011.064 1.057l-.498.501-.002.002a4.5 4.5 0 01-6.364-6.364l7-7a4.5 4.5 0 016.368 6.36l-3.455 3.553A2.625 2.625 0 119.52 9.52l3.45-3.451a.75.75 0 111.061 1.06l-3.45 3.451a1.125 1.125 0 001.587 1.595l3.454-3.553a3 3 0 000-4.242z" clip-rule="evenodd" />
            </svg>
            <span class="sr-only">Attach a file</span>
          </button>
        </div>
        <div class="flex items-center">
          <div>
            <label id="listbox-label" class="sr-only">Your mood</label>
            <div class="relative">
              <button type="button" class="relative -m-2.5 flex h-10 w-10 items-center justify-center rounded-full text-gray-400 hover:text-gray-500" aria-haspopup="listbox" aria-expanded="true" aria-labelledby="listbox-label">
                <span class="flex items-center justify-center">
                  <!-- Placeholder label, show/hide based on listbox state. -->
                  <span>
                    <svg class="h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.536-4.464a.75.75 0 10-1.061-1.061 3.5 3.5 0 01-4.95 0 .75.75 0 00-1.06 1.06 5 5 0 007.07 0zM9 8.5c0 .828-.448 1.5-1 1.5s-1-.672-1-1.5S7.448 7 8 7s1 .672 1 1.5zm3 1.5c.552 0 1-.672 1-1.5S12.552 7 12 7s-1 .672-1 1.5.448 1.5 1 1.5z" clip-rule="evenodd" />
                    </svg>
                    <span class="sr-only">Add your mood</span>
                  </span>
                  <!-- Selected item label, show/hide based on listbox state. -->
                  <span>
                    <span class="flex h-8 w-8 items-center justify-center rounded-full bg-red-500">
                      <svg class="h-5 w-5 flex-shrink-0 text-white" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                        <path fill-rule="evenodd" d="M13.5 4.938a7 7 0 11-9.006 1.737c.202-.257.59-.218.793.039.278.352.594.672.943.954.332.269.786-.049.773-.476a5.977 5.977 0 01.572-2.759 6.026 6.026 0 012.486-2.665c.247-.14.55-.016.677.238A6.967 6.967 0 0013.5 4.938zM14 12a4 4 0 01-4 4c-1.913 0-3.52-1.398-3.91-3.182-.093-.429.44-.643.814-.413a4.043 4.043 0 001.601.564c.303.038.531-.24.51-.544a5.975 5.975 0 011.315-4.192.447.447 0 01.431-.16A4.001 4.001 0 0114 12z" clip-rule="evenodd" />
                      </svg>
                    </span>
                    <span class="sr-only">Excited</span>
                  </span>
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
              <ul class="absolute bottom-10 z-10 -ml-6 w-60 rounded-lg bg-white py-3 text-base shadow ring-1 ring-black ring-opacity-5 focus:outline-none sm:ml-auto sm:w-64 sm:text-sm" tabindex="-1" role="listbox" aria-labelledby="listbox-label" aria-activedescendant="listbox-option-5">
                <!--
                  Select option, manage highlight styles based on mouseenter/mouseleave and keyboard navigation.

                  Highlighted: "bg-gray-100", Not Highlighted: "bg-white"
                -->
                <li class="bg-white relative cursor-default select-none px-3 py-2" id="listbox-option-0" role="option">
                  <div class="flex items-center">
                    <div class="bg-red-500 flex h-8 w-8 items-center justify-center rounded-full">
                      <svg class="text-white h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                        <path fill-rule="evenodd" d="M13.5 4.938a7 7 0 11-9.006 1.737c.202-.257.59-.218.793.039.278.352.594.672.943.954.332.269.786-.049.773-.476a5.977 5.977 0 01.572-2.759 6.026 6.026 0 012.486-2.665c.247-.14.55-.016.677.238A6.967 6.967 0 0013.5 4.938zM14 12a4 4 0 01-4 4c-1.913 0-3.52-1.398-3.91-3.182-.093-.429.44-.643.814-.413a4.043 4.043 0 001.601.564c.303.038.531-.24.51-.544a5.975 5.975 0 011.315-4.192.447.447 0 01.431-.16A4.001 4.001 0 0114 12z" clip-rule="evenodd" />
                      </svg>
                    </div>
                    <span class="ml-3 block truncate font-medium">Excited</span>
                  </div>
                </li>
                <!--
                  Select option, manage highlight styles based on mouseenter/mouseleave and keyboard navigation.

                  Highlighted: "bg-gray-100", Not Highlighted: "bg-white"
                -->
                <li class="bg-white relative cursor-default select-none px-3 py-2" id="listbox-option-1" role="option">
                  <div class="flex items-center">
                    <div class="bg-pink-400 flex h-8 w-8 items-center justify-center rounded-full">
                      <svg class="text-white h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                        <path d="M9.653 16.915l-.005-.003-.019-.01a20.759 20.759 0 01-1.162-.682 22.045 22.045 0 01-2.582-1.9C4.045 12.733 2 10.352 2 7.5a4.5 4.5 0 018-2.828A4.5 4.5 0 0118 7.5c0 2.852-2.044 5.233-3.885 6.82a22.049 22.049 0 01-3.744 2.582l-.019.01-.005.003h-.002a.739.739 0 01-.69.001l-.002-.001z" />
                      </svg>
                    </div>
                    <span class="ml-3 block truncate font-medium">Loved</span>
                  </div>
                </li>
                <!--
                  Select option, manage highlight styles based on mouseenter/mouseleave and keyboard navigation.

                  Highlighted: "bg-gray-100", Not Highlighted: "bg-white"
                -->
                <li class="bg-white relative cursor-default select-none px-3 py-2" id="listbox-option-2" role="option">
                  <div class="flex items-center">
                    <div class="bg-green-400 flex h-8 w-8 items-center justify-center rounded-full">
                      <svg class="text-white h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.536-4.464a.75.75 0 10-1.061-1.061 3.5 3.5 0 01-4.95 0 .75.75 0 00-1.06 1.06 5 5 0 007.07 0zM9 8.5c0 .828-.448 1.5-1 1.5s-1-.672-1-1.5S7.448 7 8 7s1 .672 1 1.5zm3 1.5c.552 0 1-.672 1-1.5S12.552 7 12 7s-1 .672-1 1.5.448 1.5 1 1.5z" clip-rule="evenodd" />
                      </svg>
                    </div>
                    <span class="ml-3 block truncate font-medium">Happy</span>
                  </div>
                </li>
                <!--
                  Select option, manage highlight styles based on mouseenter/mouseleave and keyboard navigation.

                  Highlighted: "bg-gray-100", Not Highlighted: "bg-white"
                -->
                <li class="bg-white relative cursor-default select-none px-3 py-2" id="listbox-option-3" role="option">
                  <div class="flex items-center">
                    <div class="bg-yellow-400 flex h-8 w-8 items-center justify-center rounded-full">
                      <svg class="text-white h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm-3.536-3.475a.75.75 0 001.061 0 3.5 3.5 0 014.95 0 .75.75 0 101.06-1.06 5 5 0 00-7.07 0 .75.75 0 000 1.06zM9 8.5c0 .828-.448 1.5-1 1.5s-1-.672-1-1.5S7.448 7 8 7s1 .672 1 1.5zm3 1.5c.552 0 1-.672 1-1.5S12.552 7 12 7s-1 .672-1 1.5.448 1.5 1 1.5z" clip-rule="evenodd" />
                      </svg>
                    </div>
                    <span class="ml-3 block truncate font-medium">Sad</span>
                  </div>
                </li>
                <!--
                  Select option, manage highlight styles based on mouseenter/mouseleave and keyboard navigation.

                  Highlighted: "bg-gray-100", Not Highlighted: "bg-white"
                -->
                <li class="bg-white relative cursor-default select-none px-3 py-2" id="listbox-option-4" role="option">
                  <div class="flex items-center">
                    <div class="bg-blue-500 flex h-8 w-8 items-center justify-center rounded-full">
                      <svg class="text-white h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                        <path d="M1 8.25a1.25 1.25 0 112.5 0v7.5a1.25 1.25 0 11-2.5 0v-7.5zM11 3V1.7c0-.268.14-.526.395-.607A2 2 0 0114 3c0 .995-.182 1.948-.514 2.826-.204.54.166 1.174.744 1.174h2.52c1.243 0 2.261 1.01 2.146 2.247a23.864 23.864 0 01-1.341 5.974C17.153 16.323 16.072 17 14.9 17h-3.192a3 3 0 01-1.341-.317l-2.734-1.366A3 3 0 006.292 15H5V8h.963c.685 0 1.258-.483 1.612-1.068a4.011 4.011 0 012.166-1.73c.432-.143.853-.386 1.011-.814.16-.432.248-.9.248-1.388z" />
                      </svg>
                    </div>
                    <span class="ml-3 block truncate font-medium">Thumbsy</span>
                  </div>
                </li>
                <!--
                  Select option, manage highlight styles based on mouseenter/mouseleave and keyboard navigation.

                  Highlighted: "bg-gray-100", Not Highlighted: "bg-white"
                -->
                <li class="bg-white relative cursor-default select-none px-3 py-2" id="listbox-option-5" role="option">
                  <div class="flex items-center">
                    <div class="bg-transparent flex h-8 w-8 items-center justify-center rounded-full">
                      <svg class="text-gray-400 h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                        <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
                      </svg>
                    </div>
                    <span class="ml-3 block truncate font-medium">I feel nothing</span>
                  </div>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
      <button type="submit" class="rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">Comment</button>
    </div>
    </form>
    </div>

  </div>


    """
  end
  def render(assigns) do
    ~H"""

    <%= live_render(
    @socket,
    Noizu.IntellectWeb.Chat,
    id: "project-chat",
    session: %{"mood" => %{selected: nil}}
    ) %>


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
