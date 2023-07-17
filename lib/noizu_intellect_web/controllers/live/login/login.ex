defmodule Noizu.IntellectWeb.LoginForm.Login do
  use Noizu.IntellectWeb, :live_component
  import Noizu.IntellectWeb.Nav.Tags

  defp error_title(_error), do: "Login"
  defp error_body(_error) do
    "An error has Occurred"
  end

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center">
    <div class="bg-white rounded-lg shadow-lg w-4/5 p-6 md:p-8 ">
    <h2 class="text-2xl font-bold mb-4">Log in to your account</h2>
    <%= if @error do %>
      <.noizu_alert error-title={ error_title(@error) } error-body={error_body(@error)} />
    <% end %>
    <form phx-submit="submit:login">
      <div class="mb-4 items-center">
        <label for="email" class="block text-gray-700 font-bold mb-2">Email Address</label>
        <input type="email" id="email" name="email" class="border rounded-lg w-full py-2 px-3" placeholder="Enter your email address" required>
      </div>
      <div class="mb-4 items-center">
        <label for="password" class="block text-gray-700 font-bold mb-2">Password</label>
        <input type="password" id="password" name="password" class="border rounded-lg w-full py-2 px-3" placeholder="Enter your password" required>
      </div>
      <div class="mb-4 flex justify-between items-center">
        <div class="flex items-center">
          <input type="checkbox" id="remember_me" name="remember_me" class="rounded border-gray-500 text-blue-500 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50" />
          <label for="remember_me" class="ml-2 text-gray-700 font-bold">Remember me</label>
        </div>
        <a href="#" phx-click="nav:sign-up" class="text-blue-500 font-bold hover:text-blue-700">Sign up</a>
      </div>
      <button type="submit" class="w-full bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded-lg focus:outline-none focus:shadow-outline-blue">
        Log in
      </button>
    </form>
    </div>
    </div>

    """
  end

end
