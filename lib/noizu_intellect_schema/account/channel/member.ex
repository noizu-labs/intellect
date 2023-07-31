defmodule Noizu.Intellect.Schema.Account.Channel.Member do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "channel_member" do
    field :channel, Noizu.Entity.Reference, primary_key: true
    field :member, Noizu.Entity.Reference, primary_key: true
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:channel, :member, :created_on, :modified_on, :deleted_on])
    |> validate_required([:channel, :member, :created_on, :modified_on])
  end
end
