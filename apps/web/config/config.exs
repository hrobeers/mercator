# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :web,
  namespace: Mercator.Web

# Configures the endpoint
config :web, Mercator.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "y/35tGW8WdXPyovXO/GXfOOt+bhVfees8G08B5qA4C6wb2phS0zcRfEVrPkqJmgj",
  render_errors: [view: Mercator.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Mercator.Web.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
