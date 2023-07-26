defmodule Noizu.Intellect.Schema.VersionedName.History do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "versioned_name_history" do
    field :version, :integer
    field :versioned_name, :integer
    field :first, :string
    field :middle, :string
    field :last, :string
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:version, :version_name, :first, :middle, :last, :created_on, :modified_on, :deleted_on])
    |> validate_required([:version, :version_name, :first, :middle, :last, :created_on, :modified_on, :deleted_on])
  end
end
