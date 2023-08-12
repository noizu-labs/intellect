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
  @persistence ecto_store(Noizu.Intellect.Schema.Account.Member, Noizu.Intellect.Repo)
  def_entity do
    identifier :integer
    field :account, nil, Noizu.Entity.Reference
    field :user, nil, Noizu.Entity.Reference
    field :details, nil, Noizu.Entity.VersionedString
    field :time_stamp, nil, Noizu.Entity.TimeStamp
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
      type: "Human Operator",
      slug: subject.user.slug,
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
