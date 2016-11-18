use Mix.Config

# Use the testnet P2TH addresses during development
config :peerassets,
  reload_interval: 60*60*1000,
  PAprod: %{label: "PAprod",
            address: "miYNy9BbMkQ8Y5VaRDor4mgH5b3FEzVySr",
            wif: "92NRcL14QbFBREH8runJAq3Q1viQiHoqTmivE8SNRGJ2Y1U6G3a"},
  PAtest: %{label: "PAtest",
            address: "mwqncWSnzUzouPZcLQWcLTPuSVq3rSiAAa",
            wif: "92oB4Eb4GBfutvtEqDZq3T5avC7pnEkPVme23qTb5mDdDesinm6"}
