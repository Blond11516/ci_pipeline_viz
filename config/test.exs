import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ci_pipeline_viz, CiPipelineVizWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "r9zhFA75fSOvv8hlx9fuPPx0k3pUT5L+tNoeat9tF3vb2W9BGpVIyYNAlRJWh12A",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
