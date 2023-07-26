defmodule Noizu.Intellect.Schema.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "user" do
    field :slug, :string
    field :name, :string
    field :profile_image, Ecto.UUID
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:slug, :name, :profile_image, :created_on, :modified_on, :deleted_on])
    |> validate_required([:slug, :name, :profile_image, :created_on, :modified_on])
  end
end
