defmodule Noizu.Intellect.Schema.User.TermAgreement do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "user_term_agreement" do
    belongs_to :user, Noizu.Intellect.Schema.User, references: :identifier
    field :agreement_version, :utc_datetime_usec
    field :created_on, :utc_datetime_usec
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:agreement_version, :user, :created_on])
    |> validate_required([:agreement_version, :user, :created_on])
  end
end
