defmodule BitcoinTool.RawAddress do
  defstruct raw: nil,
            lazy_base58check: nil

  def from_address!(address) do
    {prefix, pkh} = address |> Base58Check.decode58check

    %BitcoinTool.RawAddress{
      raw: prefix <> pkh,
      lazy_base58check: fn() -> prefix |> Base58Check.encode58check(pkh) end
    }
  end

  def from_pkh!(pkh, config) do
    prefix = config.network
    |> BitcoinTool.Network.get
    |> Map.get(:public_key_prefix)

    %BitcoinTool.RawAddress{
      raw: prefix <> pkh,
      lazy_base58check: fn() -> prefix |> Base58Check.encode58check(pkh) end
    }
  end

  def from_sh!(sh, config) do
    prefix = config.network
    |> BitcoinTool.Network.get
    |> Map.get(:script_prefix)

    %BitcoinTool.RawAddress{
      raw: prefix <> sh,
      lazy_base58check: fn() -> prefix |> Base58Check.encode58check(sh) end
    }
  end
end

defimpl BitcoinTool.Address, for: BitcoinTool.RawAddress do
  def raw(data), do: data.raw
  def hex(data), do: data.raw |> Base.encode16(case: :lower)
  def base58check(data), do: data.lazy_base58check.()
end
