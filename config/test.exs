import Config

require Noizu.ConfigHelper.Extension
import Noizu.ConfigHelper.Extension

config :noizu_labs_open_ai,
       openai_api_key: env_setting("OPENAI_API_KEY")

config :noizu_github, NoizuLabs.Github.Config,
       api_key: env_setting("GITHUB_API_KEY"),
       owner: "noizu-labs",
       repo: "the-robot-lives"

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.

# Configure your database
config :noizu_intellect, Noizu.Intellect.Repo,
       username: "postgres",
       password: "postgres",
       hostname: "localhost",
       port: 7005,
       database: "noizu_intellect",
       stacktrace: true,
       show_sensitive_data_on_connection_error: true,
       pool: Ecto.Adapters.SQL.Sandbox,
       pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :noizu_intellect, Noizu.IntellectWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "gM3SEUeZEqenvxqzLlOhj61OnY5wnA0bAwDORBtuE/Qk5S1mgueN1NcMMDwh+85C",
  server: false

# In test we don't send emails.
config :noizu_intellect, Noizu.Intellect.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
