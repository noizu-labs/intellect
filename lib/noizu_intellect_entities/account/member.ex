#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.Account.Member do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.Entity.Repo
  alias Noizu.Entity.TimeStamp

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
    alias Noizu.Intellect.User.Credential
    alias Noizu.Intellect.User.Credential.LoginPass
    alias Noizu.Intellect.Entity.Repo, as: EntityRepo
    alias Noizu.EntityReference.Protocol, as: ERP
    def_repo()
  end
end



defimpl Noizu.Intellect.Prompt.DynamicContext.Protocol, for: [Noizu.Intellect.Account.Member] do
  def prompt(subject, %{format: :markdown} = prompt_context, context, options) do
    prompt = """
    ````````nlp-definition
    ⚟human:@#{subject.user.slug}@1.0:nlp@0.5
    # Human #{subject.user.name}
    🙋 @#{subject.user.slug}
    ----
    Identifier: #{subject.identifier}
    Slug: @#{subject.user.slug}
    ## Background
    #{subject.details && subject.details.body}
    ⚞
    ````````
    """
    {:ok, prompt}
  end
  def minder(subject, prompt_context, context, options) do
    {:ok, nil}
  end
end
