defmodule Noizu.Intellect.Schema.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "account" do
    field :slug, :string
    field :profile_image, Ecto.UUID
    field :details, Noizu.Entity.Reference
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:slug, :profile_image, :details, :created_on, :modified_on, :deleted_on])
    |> validate_required([:slug, :profile_image, :details, :created_on, :modified_on])
  end
end
