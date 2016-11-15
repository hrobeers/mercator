defmodule BitcoinTool.Address do
  defstruct raw: nil,
            lazy_hex: nil,
            lazy_base58check: nil

  def from_pkh(pkh, config) do
    %BitcoinTool.Address{
      raw: pkh,
      lazy_hex: fn () -> pkh |> Base.encode16(case: :lower) end,
      lazy_base58check: fn () ->
        config.network
        |> BitcoinTool.Network.get
        |> Map.get(:public_key_prefix)
        |> Base58Check.encode58check(pkh)
      end
    }
  end
end
