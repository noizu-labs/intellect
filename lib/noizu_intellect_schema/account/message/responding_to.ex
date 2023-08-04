defmodule Noizu.Intellect.Schema.Account.Message.RespondingTo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "message_responding_to" do
    field :message, Noizu.Entity.Reference,  primary_key: true
    field :responding_to, Noizu.Entity.Reference, primary_key: true
    field :confidence, :integer
    field :comment, :string
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end
  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:message, :responding_to, :confidence, :comment, :created_on, :modified_on, :deleted_on])
    |> validate_required([:message, :responding_to, :confidence, :created_on, :modified_on])
  end
end
