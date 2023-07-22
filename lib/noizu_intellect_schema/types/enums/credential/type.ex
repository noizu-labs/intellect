defmodule Noizu.Intellect.Schema.Enum.User.Credential.Type do
  use Noizu.Ecto.Entity.Enum,
      name: :user_credential_type,
      values: [:login,:oauth]
end
