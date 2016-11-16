defmodule Bitcoin.Protocol.Types.Script do

  alias Bitcoin.Protocol.Types.TransactionInput
  alias Bitcoin.Protocol.Types.TransactionOutput

  @network Application.get_env(:rpc, :network)

  # TODO: P2SH in/out, P2PK in/out

  def parse_address(%TransactionOutput{pk_script: script}) do
    case script do
      # P2PKH output: OP_DUP OP_HASH160 20 <pubKeyHash> OP_EQUALVERIFY OP_CHECKSIG
      <<118, 169, 20, pkh :: bytes-size(20), 136, 172>> ->
        {:ok, pkh |> BitcoinTool.RawAddress.from_pkh(%BitcoinTool.Config{network: @network})}

      # Unmatched
      _ ->
        {:error, "Unable to parse address from output"}
    end
  end

  def parse_address(%TransactionInput{signature_script: script}) do
    case script do
      # P2PKH input (compressed): sig_size <signature> 33 <pubkey>
      <<sig_size, _sig :: bytes-size(sig_size), 33, pk :: bytes-size(33)>> ->
        address = pk
        |> Base.encode16(case: :lower)
        |> BitcoinTool.process!(:pubkey_hex_compressed)
        {:ok, address }

      # P2PKH input (uncompressed): sig_size <signature> 65 <pubkey>
      <<sig_size, _sig :: bytes-size(sig_size), 65, pk :: bytes-size(65)>> ->
        {:not_implemented, pk}

      # Unmatched
      _ ->
        {:error, "Unable to parse address from script"}
    end
  end

  def parse_address!(in_output) do
    case parse_address(in_output) do
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

  def parse_opreturn!(%TransactionOutput{pk_script: script}) do
    case parse_opreturn(script) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end

end
