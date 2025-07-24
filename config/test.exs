import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :schedshare, Schedshare.Repo,
  database: Path.expand("../priv/repo/test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :schedshare, SchedshareWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "SBd8oam5KkpDMTyQ2l6/q8u+wM2E5z17PTM3aAYL9yCCYEFYhhPcVX4SYbxib/Xd",
  server: false

# In test we don't send emails
config :schedshare, Schedshare.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Enable dev routes for testing admin tools
config :schedshare, dev_routes: true

# We don't want to define test databases for aliases yet.
# We want to find existing aliases and define databases for them,
# so explicitly disable this default unless covered by CI.
if System.get_env("CI") do
  config :schedshare, ecto_repos: [Schedshare.Repo]
end
