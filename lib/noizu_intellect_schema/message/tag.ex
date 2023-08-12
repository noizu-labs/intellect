defmodule Noizu.Intellect.Schema.Message.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "message_tag" do
    field :message, :integer, primary_key: true
    field :tag, :integer, primary_key: true
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:message, :tag])
    |> validate_required([:message, :tag])
  end
end
