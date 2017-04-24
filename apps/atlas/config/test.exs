use Mix.Config

config :atlas,
  db_dir: nil,
  reload_interval: 200*1000,
  start_height: -1 # First block to parse (negative means relative to last block at startup)
