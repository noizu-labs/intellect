# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config


Code.require_file("elixir-framework/archives/config_helper/helper_lib/config_helper.ex")


config :noizu_weaviate,
       endpoint: "http://localhost:7400/"

config :noizu_labs_services,
       configuration: Noizu.Intellect.Services.ConfigurationProvider

Application.put_env(:noizu_labs_config_helper, :env_prefix_map, [
  prod: "PROD_INTELLECT",
  stage: "STAGE_INTELLECT",
  dev: "DEV_INTELLECT",
  test: "TEST_INTELLECT"
])


config :noizu_labs_entities,
       entity_repo: Noizu.Intellect.Entity.Repo,
       uid_provider: Noizu.Intellect.UIDProviderModule,
       umbrella: true

config :noizu_intellect,
  ecto_repos: [Noizu.Intellect.Repo],
  redis: [
       uri: "redis://127.0.0.1:7000"
       ]

config :noizu_intellect, Noizu.IntellectWeb.Guardian,
       issuer: "noizu_intellect",
       secret_key: "lIf077euUjrkZiJKBnprpmkogsWDIrDWJZ7UakAOhNsRgje+ko7Xmk5uJbKFGdNv"
config :noizu_intellect, Noizu.IntellectWeb.Guardian.AuthPipeline,
       module: Noizu.IntellectWeb.Guardian,
       error_handler: Noizu.IntellectWeb.Guardian.AuthErrorHandler

# Configures the endpoint
config :noizu_intellect, Noizu.IntellectWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: Noizu.IntellectWeb.ErrorHTML, json: Noizu.IntellectWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Noizu.Intellect.PubSub,
  live_view: [signing_salt: "vMhfcRvA"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :noizu_intellect, Noizu.Intellect.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
