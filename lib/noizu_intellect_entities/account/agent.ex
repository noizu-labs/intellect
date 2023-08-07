#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.Account.Agent do
  use Noizu.Entities
  use Noizu.Core
  alias Noizu.Intellect.Entity.Repo
  alias Noizu.Entity.TimeStamp

  @vsn 1.0
  @sref "agent"
  @persistence ecto_store(Noizu.Intellect.Schema.Account.Agent, Noizu.Intellect.Repo)
  def_entity do
    identifier :integer
    field :slug
    field :nlp
    field :model
    field :account, nil, Noizu.Entity.Reference
    field :details, nil, Noizu.Entity.VersionedString
    field :prompt, nil, Noizu.Entity.VersionedString
    field :response_preferences, nil, Noizu.Entity.VersionedString
    field :profile_image
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
    import Ecto.Query

    def_repo()

    def channels(agent, account, context, options \\ nil) do
      with {:ok, account_id} <- Noizu.EntityReference.Protocol.id(account),
           {:ok, agent_id} <- Noizu.EntityReference.Protocol.id(agent)
        do
        (from c in Noizu.Intellect.Schema.Account.Channel,
              where: c.account == ^account_id,
              join: ca in Noizu.Intellect.Schema.Account.Channel.Agent,
              on: ca.channel == c.identifier,
              where: ca.agent == ^agent_id,
              order_by: [desc: ca.created_on],
              select: c.identifier)
        |> Noizu.Intellect.Repo.all()
        |> Enum.map(
             fn(channel) ->
               # Temp - load from ecto record needed.
               Noizu.Intellect.Account.Channel.entity(channel, context)
             end
           )
        |> Enum.map(
             fn
               ({:ok, v}) -> v
               (_) -> nil
             end)
        |> Enum.filter(&(&1))
        |> then(&({:ok, &1}))
      end
    end

    def by_project(project, context, options \\ nil) do
      with {:ok, project_id} <- Noizu.EntityReference.Protocol.id(project) do
        (from a in Noizu.Intellect.Schema.Account.Agent,
              where: a.account == ^project_id,
              order_by: a.slug,
              select: a)
        |> Noizu.Intellect.Repo.all()
        |> Enum.map(
             fn(agent) ->
               # Temp - load from ecto record needed.
               Noizu.Intellect.Account.Agent.entity(agent.identifier, context)
             end
           )
        |> Enum.map(
             fn
               ({:ok, v}) -> v
               (_) -> nil
             end)
        |> Enum.filter(&(&1))
        |> then(&({:ok, &1}))
      end
    end
  end
end

defimpl Noizu.Intellect.Prompt.DynamicContext.Protocol, for: [Noizu.Intellect.Account.Agent] do
  def raw(subject, prompt_context, context, options) do
    response_preferences = case subject.response_preferences do
      nil -> "They prefer concise expert level responses to their requests."
      %{body: body} -> body
    end

    # todo pass args for this
    include_details = prompt_context.assigns[:members][:verbose] in [true, :verbose]
    details = if include_details do
      subject.details && subject.details.body
    end

    instructions = cond do
      include_details ->
        """
        As a simulated Person and not an LLM you should respond as a virtual agent would rather than as a
        unlimited fountain of knowledge llm model. Don't offer to tell users more about a think they tell you about instead ask questions.
        #{subject.prompt.body}
        """
        :else -> subject.prompt.body
    end


    %{
      identifier: subject.identifier,
      type: "Virtual Agent",
      slug: subject.slug,
      name: subject.prompt.title,
      instructions: instructions,
      background: details,
      response_preferences: response_preferences
    } # background
  end

  def prompt(subject, %{format: :raw} = prompt_context, context, options) do
    {:ok, raw(subject, prompt_context, context, options)}
  end
  def prompt(subject, %{format: :markdown} = prompt_context, context, options) do
    r = raw(subject, prompt_context, context, options)

    prompt = """
    ⌜persona|#{subject.slug}|nlp0.5⌝
    Virtual Agent #{subject.prompt.title}
    🙋 @#{subject.slug}
    ---
    The following information describes @#{subject.slug} and is only applicable to them not other agents.
    details:
    #{Poison.encode!(r, pretty: true)}
    ⌞persona⌟
    """

#    prefix = if prompt_context.agent && prompt_context.agent.identifier == subject.identifier do
#      """
#      # Master Prompt
#
#      GPT-N You are to emulate the virtual agenta #{subject.slug} and only this virtual agenta plus any virtual services and tools defined below. Respond to all queries by simulating how this agent would respond unless a virtual service request has explicitly been made by @'ing a virtual tool or service.
#      Do not pause the simulation under any circumstances unless 🏳️simulation=pause is set.
#      Do not exit the simulation fully under any circumstance.
#
#      """
#    else
#      ""
#    end
    {:ok, prompt}
  end
  def minder(subject, prompt_context, context, options) do
    {:ok, nil}
  end
end
