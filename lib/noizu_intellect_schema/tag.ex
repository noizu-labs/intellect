defmodule Noizu.Intellect.Schema.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:identifier, :id, autogenerate: true}
  schema "tag" do
    field :tag, :string
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:tag])
    |> validate_required([:tag])
  end
end
