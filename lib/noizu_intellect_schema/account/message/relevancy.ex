defmodule Noizu.Intellect.Schema.Account.Message.Relevancy do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "message_recipient_relevance" do
    field :message, Noizu.Entity.Reference,  primary_key: true
    field :recipient, Noizu.Entity.Reference, primary_key: true
    field :relevance, :integer
    field :responding_to, Noizu.Entity.Reference
    field :comment, :string
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end
  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:message, :recipient, :relevance, :responding_to, :comment, :created_on, :modified_on, :deleted_on])
    |> validate_required([:message, :recipient, :relevance, :responding_to, :comment, :created_on, :modified_on])
  end
end
