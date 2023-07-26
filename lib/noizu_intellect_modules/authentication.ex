#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.AuthenticationModule do
  import Ecto.Query

  def login_exists?(login) do
    q = from ucp in Noizu.Intellect.Schema.User.Credential.LoginPass,
        join: uc in Noizu.Intellect.Schema.User.Credential,
        on: uc.identifier == ucp.identifier,
        join: u in Noizu.Intellect.Schema.User,
        on: u.identifier == uc.user,
        where: ucp.login == ^login,
        where: is_nil(uc.deleted_on),
        where: is_nil(u.deleted_on),
        select: uc
    case Noizu.Intellect.Repo.all(q) do
      [true] -> true
      _ -> false
    end
  end

  def authenticate(login, password, context, _options \\ nil) do
    q = from x in Noizu.Intellect.Schema.User.Credential.LoginPass,
             where: x.login == ^login,
             join: x2 in Noizu.Intellect.Schema.User.Credential,
             on: x2.identifier == x.identifier,
             join: x3 in Noizu.Intellect.Schema.User,
             on: x3.identifier == x2.user,
             where: is_nil(x2.deleted_on),
             where: is_nil(x3.deleted_on),
             select: {x, x3}
    case Noizu.Intellect.Repo.all(q) do
      [{l,u}] ->
        if Bcrypt.verify_pass(password, l.password) do
          with {:ok, user} <- Noizu.Intellect.User.entity(u.identifier, context) do
            {:ack, user}
            else
            _ -> :nack
          end
        else
          :nack
        end
      _ ->
        Bcrypt.verify_pass(password, "1234")
        :nack
    end
  end

end
