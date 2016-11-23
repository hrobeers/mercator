use Mix.Config

# Use the testnet P2TH addresses during development
config :peerassets,
  reload_interval: 60*60*1000,
  PAprod: %{label: "PAprod",
            address: "miHhMLaMWubq4Wx6SdTEqZcUHEGp8RKMZt",
            wif: "cTJVuFKuupqVjaQCFLtsJfG8NyEyHZ3vjCdistzitsD2ZapvwYZH"},
  PAtest: %{label: "PAtest",
            address: "mvfR2sSxAfmDaGgPcmdsTwPqzS6R9nM5Bo",
            wif: "cQToBYwzrB3yHr8h7PchBobM3zbrdGKj2LtXqg7NQLuxsHeKJtRL"}
