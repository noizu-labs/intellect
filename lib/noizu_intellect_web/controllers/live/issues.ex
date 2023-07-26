
defmodule Noizu.IntellectWeb.Issues do
  use Noizu.IntellectWeb, :live_view
  import Noizu.IntellectWeb.CoreComponents
  require Logger
  def render(assigns) do
    ~H"""
    <div id="human-contacts" class="card">
      <h1 class="heading prose prose-xl">Github Issues!</h1>
      <ul class="divide-y divide-gray-100">
        <%= if @issues do %>
          <%= for issue <- @issues.issues do %>
            <li class="flex flex-col gap-x-4 py-1">
              <span class="">
                <a class="text-slate-500 underline" target="_new" href={issue.html_url }>#<%= issue.number %></a>
                <span phx-click="show:issue" phx-value-issue={issue.number} ><%= issue.title %></span>
              </span>
            </li>
          <% end %>
        <% else %>
          <li class="flex justify-center">
    <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-black" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
          </li>
        <% end %>
        <li phx-click={show_create_issue()} class="flex gap-x-4 py-4 mx-auto justify-center">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v12m6-6H6" />
          </svg>
        </li>
      </ul>





    </div>

    <.modal show={false} title="hello" id="show-issue">
      <%= if @selected do %>
      <h1 class="prose prose-xl">#<%= @selected.number %> <%= @selected.title %></h1>
      <div class="card">
        <div class="card-body">
          <pre class="overflow-scroll"><%= @selected.body %></pre>
        </div>
      </div>
      <% end %>
    </.modal>

    <.modal show={false} id="create-issue">
    <h2>Create GitHub Issue</h2>
    <form phx-submit="submit:issue" class="w-full">
      <div class="form-group">
        <label for="issue-title">Title:</label>
        <input type="text" id="issue-title" name="issue-title" required="" class="w-full">
      </div>
      <div class="form-group">
        <label for="issue-description">Description:</label>
        <textarea id="issue-description" name="issue-description" required="" class="w-full"></textarea>
      </div>
      <div class="form-group">
        <label for="issue-labels">Labels:</label>
        <input type="text" id="issue-labels" name="issue-labels">
      </div>
      <button type="submit"
      class="
        w-fit
        px-4
        py-2
        my-2
        text-sm font-semibold text-white
        bg-green-600
        rounded-md
        shadow-sm
        hover:bg-blue-700 focus:ring-blue-500 focus:ring-offset-2 focus:ring-2 focus:outline-none"
      >Create Issue!</button>
    </form>
    </.modal>

    """
  end

  def show_create_issue() do
    show_modal("create-issue")
  end

  def show_issue(issue, socket) do
    with %{issues: issues} <- socket.assigns[:issues],
         {:ok, issue} <- Enum.find_value(issues, &(&1.number == issue && {:ok, &1}))
      do
        Logger.error("SHOW ISSUE")
      js = show_modal("show-issue")
      socket = socket
               |> assign(selected: issue)
               |> push_event("js_push", %{js: js.ops})
      {:noreply, socket}
    else
      _ -> {:noreply, socket}
    end
  end

  def submit_issue(body, socket) do
    title = body["issue-title"]
    description = body["issue-description"]
    labels = String.split(body["issue-labels"], ",")
             |> Enum.map(&(String.trim(&1)))

    Logger.info """
    Create Issue:
    Title: #{title}
    Description: #{description}
    Labels: #{inspect labels}
    """

    body = %{
      title: title,
      body: description,
      labels: labels
    }

    Noizu.Github.Api.Issues.create(body, nil)
    {:noreply, socket}
  end


  #=========================
  #
  #=========================
  def handle_event("submit:issue" = event, body, socket) do
    submit_issue(body, socket)
  end
  def handle_event("show:issue" , %{"issue" => issue}, socket) do
    show_issue(String.to_integer(issue), socket)
  end

  def handle_event(event, body, socket) do
    Logger.info """
    Uncaught EVENT: #{__MODULE__} <- #{inspect event}
    Body #{inspect body}
    """
    {:noreply, socket}
  end

  #=========================
  #
  #=========================
  def handle_info({:issues_loaded, issues}, socket) do
    socket = socket
             |> assign(issues: issues)
    {:noreply, socket}
  end

  def handle_info(info, socket) do
    Logger.info """
    Uncaught Info: #{__MODULE__} <- #{inspect info}
    """
    {:noreply, socket}
  end

  def load_issues(s \\ nil) do
    s = s || self()
    spawn fn ->
      issues = case Noizu.Github.Api.Issues.list() do
        {:ok, issues} -> send(s, {:issues_loaded, issues})
        _ ->
          Process.sleep(5000)
          load_issues(s)
      end
    end
  end

  def mount(_, session, socket) do
    load_issues()
    socket = socket
             |> assign(issues: nil)
             |> assign(selected: nil)
    {:ok, socket, layout: {Noizu.IntellectWeb.Layouts, :sparse}}
  end
end
