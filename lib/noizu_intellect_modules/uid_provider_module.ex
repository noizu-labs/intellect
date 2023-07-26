#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.UIDProviderException do
  defexception [:detail, :message]
end

defmodule Noizu.Intellect.UIDProviderModule do

  def ref(identifier) when is_integer(identifier) do
    index = rem(identifier, 1000)
    key = :"repo_lookup_by_index_#{index}"
    case FastGlobal.get(key, :__noizu_not_found__) do
      :__noizu_not_found__ ->
        query = "SELECT current_value FROM get_uid_repo($1)"
        case Ecto.Adapters.SQL.query(Noizu.Intellect.Repo, query, [identifier])  do
          {:ok, %{rows: [[v]]}} when is_bitstring(v) ->
            repo = String.to_atom(v)
            entity = Module.split(repo)
                     |> Enum.slice(0..-2)
                     |> Module.concat()
            FastGlobal.put(key, entity)
            apply(entity, :ref, [identifier])
          error -> {:error, error}
        end
      entity when is_atom(entity) ->
        apply(entity, :ref, [identifier])
    end
  end

  #-------------------------------------
  #
  #-------------------------------------
  def repo_uuid(repo) do
    UUID.uuid3(:dns, "#{repo}") |> UUID.string_to_binary!()
  end

  def generate(repo, _) do
    uuid = repo_uuid(repo)
    IO.puts "GENEREATE FOR #{repo}"
    query = "SELECT generate_uid($1)"
    case Ecto.Adapters.SQL.query(Noizu.Intellect.Repo, query, ["#{repo}"]) |> IO.inspect do
      {:ok, %{rows: [[v]]}} when is_integer(v) -> {:ok, v}
      error -> {:error, error}
    end
  end

  def add_repo(repo) do
    Noizu.Intellect.Repo.query("SELECT create_uid_sequence(uuid_generate_v3(uuid_ns_dns(), $1), $2)", ["#{repo}", "#{repo}"])
  end

  def drop_repo(repo) do
    Noizu.Intellect.Repo.query("SELECT drop_uid_sequence(uuid_generate_v3(uuid_ns_dns(), $1))", ["#{repo}"])
  end

  def reset_repo(repo, value) do
    Noizu.Intellect.Repo.query("SELECT set_uid_sequence(uuid_generate_v3(uuid_ns_dns(), $1), $2)", ["#{repo}", value])
  end
end
