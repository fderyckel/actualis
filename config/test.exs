import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
test_database = "actualis_test#{System.get_env("MIX_TEST_PARTITION")}"

config :actualis_core, Actualis.Repo,
  url: System.get_env("ACTUALIS_TEST_DATABASE_URL", "ecto://localhost:55433/#{test_database}"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :actualis_core,
  capability_handlers: [
    Actualis.ConformanceFixture.Handler,
    ActualisManufacturing.MovePallet
  ]

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :actualis_web, ActualisWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "rPvXV7htamY5jO6j4MgC2tMTbF4L/e6c2x8hKYk8qChMmJmqBGARNq4CFPT3SRb+",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
