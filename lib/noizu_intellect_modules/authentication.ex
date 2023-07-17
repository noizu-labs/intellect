#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.AuthenticationModule do
  import Ecto.Query

  def login_exists?(login) do
#    q = from x in Noizu.Intellect.Schema.Credential.Login,
#             where: x.login == ^login,
#             where: is_nil(x.deleted_on),
#             join: x2 in Noizu.Intellect.Schema.Credential,
#             on: x2.identifier == x.credential_id,
#             join: x3 in Noizu.Intellect.Schema.User,
#             on: x3.identifier == x2.user_id,
#             select: {x, x3}
#    case Noizu.Intellect.Repo.all(q) do
#      [] -> false
#      v when is_list(v) ->
#        true
#      _ -> false
#    end
    false
  end

  def authenticate(login, password) do
#    q = from x in Noizu.Intellect.Schema.Credential.Login,
#             where: x.login == ^login,
#             where: is_nil(x.deleted_on),
#             join: x2 in Noizu.Intellect.Schema.Credential,
#               on: x2.identifier == x.credential_id,
#             join: x3 in Noizu.Intellect.Schema.User,
#             on: x3.identifier == x2.user_id,
#             select: {x, x3}
#    case Noizu.Intellect.Repo.all(q) do
#      [{l,u}] ->
#        if Bcrypt.verify_pass(password, l.pass) do
#          {:ack, %Noizu.Intellect.User{
#            identifier: u.identifier,
#            name: u.name,
#            last_terms: u.last_terms,
#            time_stamp: %{
#              created_on: u.created_on,
#              modified_on: u.modified_on,
#              deleted_on: u.deleted_on
#            }
#          }
#          }
#        else
#          :nack
#        end
#      _ ->
#        Bcrypt.verify_pass(password, "1234")
#        :nack
#    end
    Bcrypt.verify_pass(password, "1234")
    :nack
  end

end
