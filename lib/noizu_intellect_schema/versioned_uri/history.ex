defmodule Noizu.Intellect.Schema.VersionedURI.History do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "versioned_uri_history" do
    field :version, :integer
    field :versioned_uri, :integer
    field :title, :string
    field :uri, :string
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:version, :versioned_uri, :title, :uri, :created_on, :modified_on, :deleted_on])
    |> validate_required([:version, :versioned_uri, :title, :uri, :created_on, :modified_on, :deleted_on])
  end
end
