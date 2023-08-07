defmodule Noizu.IntellectWeb.PageController do
  use Noizu.IntellectWeb, :controller
  import Noizu.Core.Helpers
  require Noizu.EntityReference.Records
  require Noizu.EntityReference.Protocol
  alias Noizu.EntityReference.Records, as: R
  alias Noizu.EntityReference.Protocol, as: ERP

  def home(conn, params) do
    # The home page is often custom made,
    # so skip the default app layout.
    context = Noizu.Context.system()
    with active_user = %Noizu.Intellect.User{} <- Noizu.IntellectWeb.Guardian.Plug.current_resource(conn),
         {:ok, context} <- Noizu.Context.dummy_for_user(active_user, context),
         {:ok, {active_project, active_member}} <- Noizu.Intellect.User.default_project(active_user, context),
         {:ok, channel} <- Noizu.Intellect.Account.channel_by_slug(active_project, params["channel"] || "general", context)
      do
      render(conn, :home,
        %{
          active_member: active_member,
          active_user: active_user,
          active_project: active_project,
          active_channel: channel,
          context: context,
          layout: false
        }
      )
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
