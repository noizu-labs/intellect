defmodule Noizu.Intellect.Repo.Migrations.WeaviateInitial do
  use Ecto.Migration

  def up do
    children = [
      Noizu.Intellect.Redis,
    ]
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Noizu.Intellect.Supervisor]
    s = Supervisor.start_link(children, opts)

    Noizu.Intellect.Redis.flush()
    Noizu.Weaviate.Application.start(nil, nil)
    Noizu.Weaviate.Api.Schema.Class.delete(Noizu.Intellect.Weaviate.Message)
    Noizu.Weaviate.Api.Schema.Class.delete(Noizu.Intellect.Weaviate.Memory)
    Noizu.Weaviate.Api.Schema.Class.create(Noizu.Intellect.Weaviate.Message)
    Noizu.Weaviate.Api.Schema.Class.create(Noizu.Intellect.Weaviate.Memory)
  end
end
