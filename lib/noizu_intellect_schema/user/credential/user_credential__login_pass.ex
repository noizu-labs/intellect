defmodule Noizu.Intellect.Schema.User.Credential.LoginPass do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "user_credential__login_pass" do
    field :login, :string
    field :password, :string
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:login, :password])
    |> validate_required([:login, :password])
  end
end
