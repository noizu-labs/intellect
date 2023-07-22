defmodule Noizu.IntellectWeb.LoginForm.SignUp do
  use Noizu.IntellectWeb, :live_component
  import Noizu.IntellectWeb.Nav.Tags

  defp error_title(_error), do: "Sign Up"
  defp error_body({:error, :user_exists}), do: "Account Already Exists"
  defp error_body(_error) do
    "An Error Has Occurred"
  end

  def render(assigns) do
    ~H"""
    <div class="flex justify-center items-center">
    <div class="bg-white rounded-lg shadow-lg w-4/5 p-6 md:p-8 ">
    <h2 class="text-2xl font-bold mb-4">Sign Up</h2>

    <%= if @error do %>
      <.noizu_alert error-title={ error_title(@error) } error-body={error_body(@error)} />
    <% end %>
    <form name="signup" phx-submit="submit:sign-up" >
      <div class="mb-4">
        <label for="name" class="block text-gray-700 font-bold mb-2">Name</label>
        <input type="text" id="name" name="name" class="border rounded-lg py-2 px-3 w-full" value={assigns[:form]["name"]}  placeholder="Enter your name" required>
      </div>
      <div class="mb-4">
        <label for="email" class="block text-gray-700 font-bold mb-2">Email Address</label>
        <input type="email" id="email" name="email" class="border rounded-lg py-2 px-3 w-full" value={assigns[:form]["email"]} placeholder="Enter your email address" required>
      </div>
      <div class="mb-4">
        <label for="password" class="block text-gray-700 font-bold mb-2">Password</label>
        <input type="password" id="password" name="password" class="border rounded-lg py-2 px-3 w-full" value={assigns[:form]["password"]}  placeholder="Enter your password" required>
      </div>
      <div class="mb-4 flex justify-between items-center">
        <div class="flex items-center">
          <input
            type="checkbox"
            id="terms_and_conditions"
            name="terms_and_conditions"
            checked={              (assigns[:form]["terms_and_conditions"] == "on") }
            class="rounded border-gray-500 text-blue-500 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50"
            required
          />
          <label for="terms_and_conditions" class="ml-2 text-gray-700 font-bold">I agree to the <a href="terms-and-conditions" target="new"  class="text-blue-500 font-bold hover:text-blue-700">Terms and Conditions</a></label>
        </div>
        <a href="#" phx-click="nav:login" class="text-blue-500 font-bold hover:text-blue-700">Log In</a>
      </div>




      <button type="submit" class="w-full bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded-lg focus:outline-none focus:shadow-outline-blue">
        Sign Up
      </button>
    </form>
    </div>
    </div>

    """
  end

end
