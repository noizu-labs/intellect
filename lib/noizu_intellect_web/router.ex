defmodule Noizu.IntellectWeb.Router do
  use Noizu.IntellectWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {Noizu.IntellectWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :secure_browser do
    plug Noizu.IntellectWeb.Guardian.AuthPipeline
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Noizu.IntellectWeb do
    scope "/documents/v1.0", Documents.V1_0 do
      get "/image/:type/:image", ImageController, :get
    end

    pipe_through :browser
    get "/terms-and-conditions", PageController, :terms
    post "/login", PageController, :login
    get "/logout", PageController, :logout

    pipe_through :secure_browser
    get "/", PageController, :home
    live "/profile", Profile
  end

  # Other scopes may use custom stacks.
  # scope "/api", Noizu.IntellectWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:noizu_intellect, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: Noizu.IntellectWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
