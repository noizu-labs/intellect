defmodule Noizu.Intellect.Schema.Account.Agent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "account_agent" do
    field :slug, :string
    field :model, Ecto.Enum, values: [:gpt4,:gpt4_32,:gpt35_turbo,:gpt35_turbo_16]
    field :nlp, Ecto.Enum, values: [:nlp_v0p5]
    field :account, Noizu.Entity.Reference
    field :details, Noizu.Entity.Reference
    field :prompt, Noizu.Entity.Reference
    field :profile_image, Ecto.UUID
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:slug, :model, :nlp, :account, :details, :prompt, :profile_image, :created_on, :modified_on, :deleted_on])
    |> validate_required([:slug, :model, :nlp, :account, :details, :prompt, :profile_image, :created_on, :modified_on])
  end
end
