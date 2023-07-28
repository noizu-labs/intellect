defmodule Noizu.Intellect.Schema.Account.Channel.Agent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "channel_agent" do
    field :channel, Noizu.Entity.Reference
    field :agent, Noizu.Entity.Reference
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:channel, :agent, :created_on, :modified_on, :deleted_on])
    |> validate_required([:channel, :agent, :created_on, :modified_on])
  end
end
