defmodule Noizu.Intellect.Schema.User.Credential.OAuth do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "user_credential__oauth" do
    field :provider, :string
    field :account, :string
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:provider, :account])
    |> validate_required([:provider, :account])
  end
end
