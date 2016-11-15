defmodule BitcoinTool.Network do
  defstruct public_key_prefix: 0,
            script_prefix: 128,
            private_key_prefix: 5

  def get("peercoin") do
    %BitcoinTool.Network{
      public_key_prefix: 55,
      script_prefix: 117,
      private_key_prefix: 183
    }
  end

  def get("peercoin-testnet") do
    %BitcoinTool.Network{
      public_key_prefix: 111,
      script_prefix: 196,
      private_key_prefix: 239
    }
  end
end
