defmodule Noizu.IntellectWeb.Guardian do
  use Guardian, otp_app: :noizu_intellect
  require Logger
  def subject_for_token(_user = %Noizu.Intellect.User{identifier: id}, _claims) do
    # You can use any value for the subject of your token but
    # it should be useful in retrieving the resource later, see
    # how it being used on `resource_from_claims/1` function.
    # A unique `id` is a good subject, a non-unique email address
    # is a poor subject.
    sub = "ref.user." <> Integer.to_string(id)
    {:ok, sub}
  end
  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  def get_resource_by_id("ref.user." <> id) do
    id = String.to_integer(id)
    with user = %{} <- Noizu.Intellect.User.entity(id, Noizu.Context.system()) do
      {:ok, user}
    end
  end

  def get_resource_by_id(_sub) do
    nil
  end

  def resource_from_claims(%{"sub" => id}) do
    # Here we'll look up our resource from the claims, the subject can be
    # found in the `"sub"` key. In above `subject_for_token/2` we returned
    # the resource id so here we'll rely on that to look it up.
    Noizu.IntellectWeb.Guardian.get_resource_by_id(id)
  end
  def resource_from_claims(_claims) do
    IO.puts "NO MATCH"
    {:error, :reason_for_error}
  end
end
