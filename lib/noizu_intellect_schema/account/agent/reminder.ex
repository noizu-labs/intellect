defmodule Noizu.Intellect.Schema.Account.Agent.Reminder do
  use Ecto.Schema
  import Ecto.Changeset

  @derive Noizu.EntityReference.Protocol
  @primary_key {:identifier, :integer, autogenerate: false}
  schema "account_agent_reminder" do
    field :agent, Noizu.Entity.Reference
    field :parent, Noizu.Entity.Reference
    field :name, :string
    field :brief, :string
    field :type, Ecto.Enum, values: [:objective_reminder, :objective_pinger, :reminder, :other]
    field :digest, :string
    field :condition, :string
    field :condition_met, :boolean
    field :instructions, :string
    field :remind_after, :utc_datetime_usec
    field :remind_until, :utc_datetime_usec
    field :repeat, :integer
    field :condition_checked_on, :utc_datetime_usec
    field :sent_on, :utc_datetime_usec

    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
    field :__loader__, :map, virtual: true
  end

  use Noizu.Entity.Meta.IntegerIdentifier
  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:agent, :parent, :type, :digest, :condition, :condition_met, :instructions, :remind_after, :remind_until, :repeat, :condition_checked_on, :sent_on, :created_on, :modified_on, :deleted_on])
    |> validate_required([:agent, :type, :member, :remind_after, :instructions, :created_on, :modified_on])
  end
end
