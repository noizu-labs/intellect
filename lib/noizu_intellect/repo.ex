defmodule NoizuIntellect.Repo do
  use Ecto.Repo,
    otp_app: :noizu_intellect,
    adapter: Ecto.Adapters.Postgres
end
