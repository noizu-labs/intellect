defmodule Noizu.Intellect.Schema.User.Credential do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "user_credential" do
    field :weight, :integer
    field :type, Noizu.Intellect.Schema.Enum.User.Credential.Type
    field :user_id, Noizu.Entity.Reference
    field :details_id, Noizu.Entity.Reference
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:weight, :user_id, :details_id, :created_on, :modified_on, :deleted_on])
    |> validate_required([:weight, :user_id, :details_id, :created_on, :modified_on])
  end
end
