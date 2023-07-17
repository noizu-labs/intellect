defmodule Noizu.Intellect.Schema.VersionedString.History do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "versioned_string_history" do
    field :version, :integer
    belongs_to :versioned_string, Noizu.Intellect.Schema.VersionedString, references: :identifier
    field :title, :string
    field :body, :string
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:version, :versioned_string_id, :title, :body, :created_on, :modified_on, :deleted_on])
    |> validate_required([:version, :versioned_string_id, :title, :body, :created_on, :modified_on, :deleted_on])
  end
end
