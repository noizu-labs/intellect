defmodule Noizu.Intellect.Schema.Service do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :integer, autogenerate: false}
  schema "service" do
    field :slug, :string
    field :prompt, Noizu.Entity.Reference
    field :minder, Noizu.Entity.Reference
    field :details, Noizu.Entity.Reference
    field :type, Ecto.Enum, values: [:service, :tool, :intuition_pump]
    field :settings, :map
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:slug, :prompt, :minder, :type, :settings, :created_on, :modified_on, :deleted_on])
    |> validate_required([:slug, :prompt, :minder, :type, :settings, :created_on, :modified_on, :created_on, :modified_on])
  end
end
