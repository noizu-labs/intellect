defmodule Noizu.Intellect.Schema.Account.Agent.Objective.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  @derive Noizu.EntityReference.Protocol
  @primary_key false
  schema "account_Agent_objective_participant" do
    field :objective, Noizu.Entity.Reference, primary_key: true
    field :participant, Noizu.Entity.Reference, primary_key: true
    #field :details, Noizu.Entity.Reference
    #field :channel, Noizu.Entity.Reference
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
    field :__loader__, :map, virtual: true
  end

  use Noizu.Entity.Meta.IntegerIdentifier
  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:objective, :participant, :created_on, :modified_on, :deleted_on])
    |> validate_required([:objective, :participant, :created_on, :modified_on])
  end
end
