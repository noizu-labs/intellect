defmodule Noizu.Intellect.Schema.Account.Agent.Objective do
  use Ecto.Schema
  import Ecto.Changeset


  @derive Noizu.EntityReference.Protocol
  @primary_key {:identifier, :integer, autogenerate: false}
  schema "account_agent_objective" do
    field :owner, Noizu.Entity.Reference
    field :name, :string
    field :brief, :string
    field :tasks, :string
    field :status, Ecto.Enum, values: [:new,:in_progress,:blocked,:pending,:completed,:in_review,:stalled]
    #field :remind_after, :utc_datetime_usec

    #field :remind_instructions, :string


    field :participants, :map, virtual: true
    field :reminders, :map, virtual: true
    field :pings, :map, virtual: true

    #field :ping_after, :utc_datetime_usec
    #field :ping_instructions, :string

    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
    field :__loader__, :map, virtual: true
  end

  use Noizu.Entity.Meta.IntegerIdentifier
  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:owner, :name, :brief, :tasks, :status, :remind_after, :remind_instructions, :ping_after, :ping_instructions, :created_on, :modified_on, :deleted_on])
    |> validate_required([:owner, :name, :brief, :tasks, :status, :created_on, :modified_on])
  end
end
