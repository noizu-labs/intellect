#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.Account.Member do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.Entity.Repo

  @vsn 1.0
  @sref "account-member"

  @persistence redis_store(Noizu.Intellect.Account.Member, Noizu.Intellect.Redis)
  @persistence ecto_store(Noizu.Intellect.Schema.Account.Member, Noizu.Intellect.Repo)
  @derive Noizu.Entity.Store.Redis.EntityProtocol


  def_entity do
    identifier :integer
    field :account, nil, Noizu.Entity.Reference
    field :user, nil, Noizu.Entity.Reference
    field :details, nil, Noizu.Entity.VersionedString
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end


  #---------------------------
  #
  #---------------------------
  @_defimpl Noizu.Entity.Store.Redis.EntityProtocol
  def as_entity(entity, settings = Noizu.Entity.Meta.Persistence.persistence_settings(table: Noizu.Intellect.Account.Member, store: Noizu.Intellect.Redis), context, options) do
    with {:ok, redis_key} <- key(entity, settings, context, options) do
      case Noizu.Intellect.Redis.get_binary(redis_key)  do
        {:ok, v} ->
          {:ok, v}
        _ -> {:ok, nil}
      end
      |> case do
           {:ok, nil} ->
             ecto_settings = Noizu.Entity.Meta.persistence(entity) |> Enum.find_value(& Noizu.Entity.Meta.Persistence.persistence_settings(&1, :type) == Noizu.Entity.Store.Ecto && &1 || nil)
             case Noizu.Entity.Store.Ecto.EntityProtocol.as_entity(entity,
                    ecto_settings,
                    context,
                    options
                  ) |> IO.inspect(label: "CACHE LOOKUP") do
               {:ok, nil} -> {:ok, nil}
               {:ok, value} ->
                 Noizu.Intellect.Redis.set_binary(redis_key, value)
                 {:ok, value}
               x -> x
             end
           v -> v
         end
    end
  end
  def as_entity(entity, settings, context, options) do
    super(entity, settings, context, options)
  end

  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
    end
  end

  defmodule Repo do
    use Noizu.Repo
    def_repo()
  end
end



defimpl Noizu.Intellect.Prompt.DynamicContext.Protocol, for: [Noizu.Intellect.Account.Member] do

  def raw(subject, prompt_context, _context, _options) do
    # There should be per agent response_preferences overrides
    response_preferences = case subject.user.response_preferences do
      nil -> "This operator is a fellow expert with advanced knowledge of physics, match and computer science. They prefer high level concise academic or technical level responses."
      %{body: body} -> body
    end

    _include_details = prompt_context.assigns[:members][:verbose] in [true, :verbose]

    %{
      identifier: subject.identifier,
      type: "human operator",
      slug: "@" <> subject.user.slug,
      name: subject.user.name,
      background: subject.details && subject.details.body,
      response_preferences: response_preferences
    }
  end

  def prompt(subject, %{format: :raw} = prompt_context, context, options) do
    {:ok, raw(subject, prompt_context, context, options)}
  end


  def prompt(subject, %{format: :markdown} = _prompt_context, _context, _options) do

    # There should be per agent response_preferences overrides
    response_preferences = case subject.user.response_preferences do
      nil -> "This operator prefers to be spoken to as a subject matter expert and expects full examples/code items/deliverables not stubs to be provided when requested. They expert full, verbose and detailed responses appropriate for a fellow subject matter expert"
      %{body: body} -> body
    end

    prompt = """
    ⌜operator|#{subject.user.slug}|nlp0.5⌝
    Human Operator #{subject.user.name}
    🙋 @#{subject.user.slug}
    ---
    details:
     identifier: #{subject.identifier}
     slug: @#{subject.user.slug}}
     background: |-1
      #{(subject.details && subject.details.body || "[NONE]")|> String.split("\n") |> Enum.join("\n  ")}
     response-preferences: |-1
      #{response_preferences}
    ⌞operator⌟
    """
    {:ok, prompt}
  end
  def minder(_subject, _prompt_context, _context, _options) do
    {:ok, nil}
  end
end
