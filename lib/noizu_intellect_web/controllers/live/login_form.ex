defmodule Noizu.IntellectWeb.LoginForm do
  use Noizu.IntellectWeb, :live_view

  def render(assigns) do
    ~H"""
      <%= if @mode == :login do %>
        <.live_component module={Noizu.IntellectWeb.LoginForm.Login} id="login-page" form={@login.form} error={@login.error} />
      <% end %>
      <%= if @mode == :sign_up do %>
        <.live_component module={Noizu.IntellectWeb.LoginForm.SignUp} id="sign-up-page" form={@signup.form} error={@signup.error} />
      <% end %>
    """
  end




  #-----------------------------
  #
  #-----------------------------
  def show_login(socket) do
    # copy sign up details if set
    login = socket.assigns[:login]
            |> update_in([:form], &(&1 || %{}))
            |> put_in([:error], nil)
            |> then(
                 fn(t) ->
                   if v = socket.assigns[:signup][:form]["email"] do
                     put_in(t, [Access.key(:form, %{}), Access.key("email")], v)
                   else
                     t
                   end
                 end)
            |> then(
                 fn(t) ->
                   if v = socket.assigns[:signup][:form]["password"] do
                     put_in(t, [Access.key(:form, %{}), Access.key("password")], v)
                   else
                     t
                   end
                 end)

    socket = socket
             |> assign(mode: :login)
             |> assign(login: login)
    {:noreply, socket}
  end


  #-----------------------------
  #
  #-----------------------------
  def show_sign_up(socket) do
    # copy sign up details if set
    signup = socket.assigns[:signup]
             |> update_in([:form], &(&1 || %{}))
             |> put_in([:error], nil)
             |> then(
                  fn(t) ->
                    if v = socket.assigns[:login][:form]["email"] do
                      put_in(t, [Access.key(:form, %{}), Access.key("email")], v)
                    else
                      t
                    end
                  end)
             |> then(
                  fn(t) ->
                    if v = socket.assigns[:login][:form]["password"] do
                      put_in(t, [Access.key(:form, %{}), Access.key("password")], v)
                    else
                      t
                    end
                  end)
    socket = socket
             |> assign(mode: :sign_up)
             |> assign(signup: signup)
    {:noreply, socket}
  end


  #-----------------------------
  #
  #-----------------------------
  def sign_up(form, socket) do
    context = Noizu.Context.system()
    options = nil

    unless Noizu.Intellect.AuthenticationModule.login_exists?(form["email"]) do
      Noizu.Intellect.User.Repo.register_with_login(form["name"], form["email"], form["password"], context, options)
      socket = (with {:ack, user} <- Noizu.Intellect.AuthenticationModule.authenticate(form["email"], form["password"], Noizu.Context.system()),
                     {:ok, jwt} <- indirect_auth(user) do
                  socket
                  |> push_event("auth", %{jwt: jwt, remember_me: false})
                else
                  _ -> socket
                end)
      {:noreply, socket}
    else
      socket = socket
               |> assign(signup: %{error: {:error, :user_exists}, form: form})
      {:noreply, socket}
    end
  end

  #-----------------------------
  #
  #-----------------------------
  def login(form, socket) do
    socket = with {:ack, user} <- Noizu.Intellect.AuthenticationModule.authenticate(form["email"], form["password"], Noizu.Context.system()) |> IO.inspect,
                  {:ok, jwt} <- indirect_auth(user) do
      socket
      |> push_event("auth", %{jwt: jwt, remember_me: form["remember_me"] == "on"})
    else
      _ -> socket
    end
    {:noreply, socket}
  end


  #-----------------------------
  #
  #-----------------------------
  def indirect_auth(user) do
    with {:ok, jwt, _} <- Noizu.IntellectWeb.Guardian.encode_and_sign(user, %{"login-only" => true}, ttl: {1, :minute}) do
      {:ok, jwt}
    end
  end

  #-----------------------------
  #
  #-----------------------------
  def handle_event("nav:login", _,  socket), do: show_login(socket)
  def handle_event("nav:sign-up", _,  socket), do: show_sign_up(socket)
  def handle_event("submit:sign-up", form,  socket), do: sign_up(form, socket)
  def handle_event("submit:login", form, socket), do: login(form, socket)
  def handle_event(_, _, socket), do: {:noreply, socket}

  #-----------------------------
  #
  #-----------------------------
  def mount(_, session, socket) do
    socket = socket
             |> assign(project: session["project"])
             |> assign(mode: :login)
             |> assign(signup: %{error: nil, form: nil})
             |> assign(login: %{error: nil, form: nil})
             |> assign(csrf: session["_csrf_token"])
    {:ok, socket, layout: {Noizu.IntellectWeb.Layouts, :sparse}}
  end

end
