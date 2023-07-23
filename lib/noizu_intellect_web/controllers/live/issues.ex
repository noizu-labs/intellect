
defmodule Noizu.IntellectWeb.Issues do
  use Noizu.IntellectWeb, :live_view
  import Noizu.IntellectWeb.CoreComponents
  require Logger
  def render(assigns) do
    ~H"""

    <div id="human-contacts" class="ml-2 card">
    <div class="heading">Team Members</div>
    <ul>


    <%= for issue <- @issues do %>
    <li><span class="status"><%= issue.number %></span><span><a href={ issue.html_url }><%= issue.title %></a></span></li>
    <% end %>
    <li phx-click={show_create_issue()}>
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
        <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v12m6-6H6" />
      </svg>
    </li>

    </ul>
    </div>

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


  def handle_event("submit:issue" = event, body, socket) do

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

    Noizu.Github.Api.Issues.create(body, nil) |> IO.inspect(label: "CREATE ISSUE")
    {:noreply, socket}
  end

  def handle_event(event, body, socket) do
    Logger.info """
    Uncaught EVENT: #{__MODULE__} <- #{inspect event}
    Body #{inspect body}
    """

    {:noreply, socket}
  end


  def mount(_, session, socket) do
    {:ok, issues} = Noizu.Github.Api.Issues.list()
    socket = socket
             |> assign(issues: issues.issues)
    {:ok, socket, layout: {Noizu.IntellectWeb.Layouts, :sparse}}
  end
end
