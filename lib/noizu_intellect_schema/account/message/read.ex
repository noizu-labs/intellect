defmodule Noizu.Intellect.Schema.Account.Message.Read do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "message_read" do
    field :message, :integer, primary_key: true
    field :recipient, :integer, primary_key: true
    field :read_on, :utc_datetime_usec
  end
  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:message, :recipient, :read_on])
    |> validate_required([:message, :recipient, :read_on])
  end
end
