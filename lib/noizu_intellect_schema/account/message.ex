defmodule Noizu.Intellect.Schema.Account.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @derive Noizu.EntityReference.Protocol
  @primary_key {:identifier, :integer, autogenerate: false}
  schema "message" do
    field :weaviate_object, Ecto.UUID
    field :sender, Noizu.Entity.Reference
    field :channel, Noizu.Entity.Reference
    field :answered_by, Noizu.Entity.Reference
    field :depth, :integer
    field :user_mood, :string # atom
    field :event, Ecto.Enum, values: [:online,:offline,:message,:function_call,:function_response]
    field :token_size, :integer
    field :contents, Noizu.Entity.Reference
    field :brief, Noizu.Entity.Reference
    field :meta, Noizu.Entity.Reference
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
    field :__loader__, :map, virtual: true
  end

  use Noizu.Entity.Meta.IntegerIdentifier

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:weaviate_object, :sender, :channel, :answered_by, :depth, :user_mood, :event, :contents, :brief, :meta, :token_size, :created_on, :modified_on, :deleted_on])
    |> validate_required([:weaviate_object, :sender, :channel, :depth, :event, :contents, :created_on, :modified_on])
  end
end
