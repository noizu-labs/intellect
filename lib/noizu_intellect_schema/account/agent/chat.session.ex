defmodule Noizu.Intellect.Schema.Account.Agent.Chat.Session do
  use Ecto.Schema
  import Ecto.Changeset

  @derive Noizu.EntityReference.Protocol
  @primary_key {:identifier, :integer, autogenerate: false}
  schema "agent_chat_session" do
    field :agent, Noizu.Entity.Reference
    field :member, Noizu.Entity.Reference
    #field :details, Noizu.Entity.Reference
    field :channel, Noizu.Entity.Reference
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
    field :__loader__, :map, virtual: true
  end

  use Noizu.Entity.Meta.IntegerIdentifier
  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:agent, :member, :channel, :created_on, :modified_on, :deleted_on])
    |> validate_required([:agent, :member, :channel, :created_on, :modified_on])
  end
end
