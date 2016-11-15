defmodule Bitcoin.Protocol.Types.Script do

  def parse_p2pkh(script, network \\ nil) do
    case script do
      # OP_DUP OP_HASH160 20 <pubKeyHash> OP_EQUALVERIFY OP_CHECKSIG
      <<118, 169, 20, pkh :: bytes-size(20), 136, 172>> ->
        {:ok, pkh |> BitcoinTool.RawAddress.from_pkh(%BitcoinTool.Config{network: network})}
      _ ->
        {:error, "Not a P2PKH script"}
    end
  end

  def parse_p2pkh!(script, network \\ nil) do
    case parse_p2pkh(script, network) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end

  def parse_opreturn(script) do
    case script do
      # OP_RETURN OP_PUSHDATA1 size <data>
      <<106, 76, _size :: bytes-size(1), data :: binary>> ->
        {:ok, data}
      # OP_RETURN OP_PUSHDATA2 size[2] <data>
      <<106, 77, _size :: bytes-size(2), data :: binary>> ->
        {:ok, data}
      # OP_RETURN OP_PUSHDATA4 size[4] <data>
      <<106, 78, _size :: bytes-size(4), data :: binary>> ->
        {:ok, data}
      # OP_RETURN size <data>
      <<106, _size :: bytes-size(1), data :: binary>> ->
        {:ok, data}
      _ ->
        {:error, "Not an OP_RETURN script"}
    end
  end

  def parse_opreturn!(script) do
    case parse_opreturn(script) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end

end
