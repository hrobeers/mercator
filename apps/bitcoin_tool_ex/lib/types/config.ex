defmodule BitcoinTool.Config do
  defstruct input_type: "private-key",
            input_format: "hex",
            network: "peercoin",
            public_key_compression: "compressed"
end
