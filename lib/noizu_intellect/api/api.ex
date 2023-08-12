defmodule Noizu.IntellectApi do

  defmodule Agents do

    defdelegate by_project(project, context, options \\ nil), to: Noizu.Intellect.Account.Agent.Repo
  end

  defmodule Messages do
    defdelegate recent(channel, context, options \\ nil), to: Noizu.Intellect.Account.Message.Repo
  end

end
