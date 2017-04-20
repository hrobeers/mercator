defmodule Bitcoin.Protocol.Types.Script do

  alias Bitcoin.Protocol.Types.TransactionInput
  alias Bitcoin.Protocol.Types.TransactionOutput
  alias Bitcoin.Protocol.Types.Outpoint
  alias Mercator.RPC

  @network Application.get_env(:rpc, :network)

  # TODO: P2SH in/out

  def parse_address!(inoutput) do
    case parse(inoutput) do
      {:address, addr} -> addr
      {type, _} -> {:error, "parse_address expected :address but received :" <> Atom.to_string(type)}
    end
  end

  def parse(%TransactionOutput{pk_script: script}) do
    case script do
      # P2PKH output: OP_DUP OP_HASH160 20 <pubKeyHash> OP_EQUALVERIFY OP_CHECKSIG
      <<118, 169, 20, pkh :: bytes-size(20), 136, 172>> ->
        {:address, pkh |> BitcoinTool.RawAddress.from_pkh!(%BitcoinTool.Config{network: @network})}

      # P2PK output (compressed): 33 <pubkey> OP_CHECKSIG
      <<33, pk :: bytes-size(33), 172>> ->
        pk |> pubkey_to_address

      # P2PK output (uncompressed): 65 <pubkey> OP_CHECKSIG
      <<65, pk :: bytes-size(65), 172>> ->
        pk |> pubkey_to_address

      # P2SH output: OP_HASH160 20 <scriptHash> OP_EQUAL
      <<169, 20, sh :: bytes-size(20), 135>> ->
        {:sh, sh}

      # OP_RETURN
      <<106, _data :: binary>> ->
        {:ok, data} = script |> parse_opreturn
        {:op_return, data}

      # Empty output
      <<>> ->
        {:empty}

      # Unmatched
      other ->
        {:error, "Unable to parse address from output script", other}
    end
  end

  def parse(%TransactionInput{previous_output:
                                      %Outpoint{hash: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>},
                                      signature_script: script
                                     }) do
    {:coinbase, script}
  end

  def parse(%TransactionInput{signature_script: script, previous_output: prev_out}) do
    case script do
      # P2PKH input (compressed): sig_size <signature> 33 <pubkey>
      <<sig_size, _sig :: bytes-size(sig_size), 33, pk :: bytes-size(33)>> ->
        pk |> pubkey_to_address

      # P2PKH input (uncompressed): sig_size <signature> 65 <pubkey>
      <<sig_size, _sig :: bytes-size(sig_size), 65, pk :: bytes-size(65)>> ->
        pk |> pubkey_to_address

      # Empty input
      <<>> ->
        {:empty}

      # Unmatched (P2PK & P2SH inputs): parse from previous output
      _other ->
        prev_out |> parse
    end
  end

  def parse(%Outpoint{hash: hash, index: index}) do
    prev_txn = hash
    |> :binary.bin_to_list |> Enum.reverse |> :binary.list_to_bin
    |> Base.encode16(case: :lower)
    |> RPC.gettransaction!

    prev_txn.outputs
    |> Enum.at(index)
    |> parse
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
    {:address, address }
  end

end
