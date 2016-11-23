# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :peerassets, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:peerassets, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

config :peerassets,
  reload_interval: 1000,
  PAprod: %{label: "PAprod",
            address: "PAprodbYvZqf4vjhef49aThB9rSZRxXsM6",
            wif: "U624wXL6iT7XZ9qeHsrtPGEiU78V1YxDfwq75Mymd61Ch56w47KE"},
  PAtest: %{label: "PAtest",
            address: "PAtesth4QreCwMzXJjYHBcCVKbC4wjbYKP",
            wif: "UAbxMGQQKmfZCwKXAhUQg3MZNXcnSqG5Z6wAJMLNVUAcyJ5yYxLP"}


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
