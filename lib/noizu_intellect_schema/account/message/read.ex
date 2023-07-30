defmodule Noizu.Intellect.Schema.Account.Message.Read do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "message_read" do
    field :message, :integer
    field :recipient, :integer
    field :read_on, :utc_datetime_usec
  end
  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:message, :recipient, :read_on])
    |> validate_required([:message, :recipient, :read_on])
  end
end
