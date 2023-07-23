defmodule Noizu.Intellect.Schema.Account.Channel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "channel" do
    field :slug, :string
    field :account, Noizu.Entity.Reference
    field :details, Noizu.Entity.Reference
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:slug, :account, :details, :created_on, :modified_on, :deleted_on])
    |> validate_required([:slug, :account, :details, :created_on, :modified_on])
  end
end
