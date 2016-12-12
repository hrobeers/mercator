defmodule Bitcoin.Protocol.Types.Script do

  alias Bitcoin.Protocol.Types.TransactionInput
  alias Bitcoin.Protocol.Types.TransactionOutput
  alias Bitcoin.Protocol.Types.Outpoint
  alias Mercator.RPC

  @network Application.get_env(:rpc, :network)

  # TODO: P2SH in/out

  def parse_address(%TransactionOutput{pk_script: script}) do
    case script do
      # P2PKH output: OP_DUP OP_HASH160 20 <pubKeyHash> OP_EQUALVERIFY OP_CHECKSIG
      <<118, 169, 20, pkh :: bytes-size(20), 136, 172>> ->
        {:ok, pkh |> BitcoinTool.RawAddress.from_pkh(%BitcoinTool.Config{network: @network})}

      # P2PK output (compressed): 33 <pubkey> OP_CHECKSIG
      <<33, pk :: bytes-size(33), 172>> ->
        pk |> pubkey_to_address

      # P2PK output (uncompressed): 65 <pubkey> OP_CHECKSIG
      <<65, pk :: bytes-size(65), 172>> ->
        pk |> pubkey_to_address

      # Empty output
      <<>> ->
        {:error, "Empty output"}

      # Unmatched
      _ ->
        {:error, "Unable to parse address from output"}
    end
  end

  def parse_address(%TransactionInput{signature_script: script, previous_output: prev_out}) do
    case script do
      # P2PKH input (compressed): sig_size <signature> 33 <pubkey>
      <<sig_size, _sig :: bytes-size(sig_size), 33, pk :: bytes-size(33)>> ->
        pk |> pubkey_to_address

      # P2PKH input (uncompressed): sig_size <signature> 65 <pubkey>
      <<sig_size, _sig :: bytes-size(sig_size), 65, pk :: bytes-size(65)>> ->
        pk |> pubkey_to_address

      # P2PK input: sig_size <signature>
      <<sig_size, _sig :: bytes-size(sig_size)>> ->
        prev_out |> parse_address

      # Unmatched
      _ ->
        {:error, "Unable to parse address from script"}
    end
  end

  def parse_address(%Outpoint{hash: hash, index: index}) do
    prev_txn = hash
    |> :binary.bin_to_list |> Enum.reverse |> :binary.list_to_bin
    |> Base.encode16(case: :lower)
    |> RPC.gettransaction!

    prev_txn.outputs
    |> Enum.at(index)
    |> parse_address
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

  defp pubkey_to_address(pubkey) do
    address = pubkey
    |> Base.encode16(case: :lower)
    |> BitcoinTool.process!(:pubkey_hex)
    {:ok, address }
  end

end
