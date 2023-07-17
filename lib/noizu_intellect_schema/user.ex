defmodule Noizu.Intellect.Schema.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "user" do
    field :name, :string
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :created_on, :modified_on, :deleted_on])
    |> validate_required([:name, :created_on, :modified_on])
  end
end
