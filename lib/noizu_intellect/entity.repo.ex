defmodule Noizu.Intellect.Entity.Repo do
  def create(entity, context, options \\ nil) do
    r = Module.concat([entity.__struct__, Repo])
    apply(r, :create, [entity, context, options])
  end

  def update(entity, context, options \\ nil) do
    r = Module.concat([entity.__struct__, Repo])
    apply(r, :update, [entity, context, options])
  end
end
