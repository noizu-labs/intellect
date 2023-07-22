defmodule Noizu.IntellectWeb.PageController do
  use Noizu.IntellectWeb, :controller
  import Noizu.Core.Helpers
  require Noizu.EntityReference.Records
  require Noizu.EntityReference.Protocol
  alias Noizu.EntityReference.Records, as: R
  alias Noizu.EntityReference.Protocol, as: ERP

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    context = Noizu.Context.system()
    with active_user = %Noizu.Intellect.User{} <- Noizu.IntellectWeb.Guardian.Plug.current_resource(conn) do
#      proj = Noizu.Intellect.Project.entity(1006, context) |> ok?()
#      active_member = Noizu.Intellect.Project.Member.Repo.by_project_and_user(proj, active_user, context, nil) |> ok?()
#      channel = R.ref(module: Noizu.Intellect.Channel, identifier: 1008)
#                |> ERP.entity(context)
#                |> ok?()
#                |> IO.inspect()
#
#      render(conn, :home,
#        %{
#          active_member: active_member,
#          active_user: active_user,
#          active_project: proj,
#          active_channel: channel,
#          layout: false
#        }
#      )
      render(conn, :home, layout: false)
    else
      _ ->
        render(conn, :login, layout: false)
    end
  end



  def terms(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :terms)
  end


  def logout(conn, _) do
    conn
    |> Noizu.IntellectWeb.Guardian.Plug.sign_out()
    |> redirect(to: "/")
  end


  def logout(conn) do
    conn
    |> Noizu.IntellectWeb.Guardian.Plug.sign_out()
    |> redirect(to: "/")
  end

  def login(conn, %{"event" => event}) do
    with {:ok, %{"login-only" => true, "sub" => sub}} <- Noizu.IntellectWeb.Guardian.decode_and_verify(event["jwt"]),
         {:ok, resource = %Noizu.Intellect.User{}} <- Noizu.IntellectWeb.Guardian.get_resource_by_id(sub) do
      cond do
        event["remember_me"] ->
          conn
          |> Noizu.IntellectWeb.Guardian.Plug.sign_in(resource)
          |> Noizu.IntellectWeb.Guardian.Plug.remember_me(resource)
          |> json(%{auth: true})
        :else ->
          conn
          |> Noizu.IntellectWeb.Guardian.Plug.sign_in(resource)
          |> json(%{auth: true})
      end
    else
      _ ->
        conn
        |> json(%{auth: false})
    end
  end

end
