defmodule BitcoinTool.Address do
  defstruct raw: nil,
            lazy_base58check: nil

  def from_pkh(pkh, config) do
    %BitcoinTool.Address{
      raw: pkh,
      lazy_base58check: fn () ->
        config.network
        |> BitcoinTool.Network.get
        |> Map.get(:public_key_prefix)
        |> Base58Check.encode58check(pkh)
      end
    }
  end

  def from_sh(sh, config) do
    %BitcoinTool.Address{
      raw: sh,
      lazy_base58check: fn () ->
        config.network
        |> BitcoinTool.Network.get
        |> Map.get(:script_prefix)
        |> Base58Check.encode58check(sh)
      end
    }
  end
end

defimpl BitcoinTool.Protocols.Address, for: BitcoinTool.Address do
  def raw(data), do: data.raw
  def hex(data), do: data.raw |> Base.encode16(case: :lower)
  def base58check(data), do: data.lazy_base58check.()
end
