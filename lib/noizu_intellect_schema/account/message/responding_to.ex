defmodule Noizu.Intellect.Schema.Account.Message.RespondingTo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "message_responding_to" do
    field :message, Noizu.Entity.Reference,  primary_key: true
    field :responding_to, Noizu.Entity.Reference, primary_key: true
    field :confidence, :integer
    field :comment, :string
    field :created_on, :utc_datetime_usec
    field :modified_on, :utc_datetime_usec
    field :deleted_on, :utc_datetime_usec
  end

  def record({:responding_to, {id, confidence, {complete, completed_by}, comment}}, message, context, options) do
    now = options[:current_time] || DateTime.utc_now()
    resp = %Noizu.Intellect.Schema.Account.Message.RespondingTo{
             message: message.identifier,
             responding_to: id,
             confidence: confidence,
             comment: comment,
             created_on: now,
             modified_on: now,
           }
           |> Noizu.Intellect.Repo.insert(on_conflict: :replace_all, conflict_target: [:message, :responding_to])
    if complete do
      with {:ok, close} <- Noizu.Intellect.Account.Message.entity(id, context) do
        completed_by = completed_by || message.identifier
        completed_by = cond do
          completed_by == message.identifier -> message
          :else ->
            with {:ok, ref} <- Noizu.Intellect.Account.Message.ref(completed_by) do
              ref
            else
              _ -> message
            end
        end
        update_in(close, [Access.key(:answered_by)], &(&1 || completed_by))
        |> Noizu.Intellect.Entity.Repo.update(context)
      end
    end
    resp
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:message, :responding_to, :confidence, :comment, :created_on, :modified_on, :deleted_on])
    |> validate_required([:message, :responding_to, :confidence, :created_on, :modified_on])
  end
end
