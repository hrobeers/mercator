defmodule Mercator.RPCTest do
  use ExUnit.Case
  doctest Mercator.RPC

  alias Bitcoin.Protocol.Types.Script
  alias Bitcoin.Protocol.Types.TransactionInput
  alias BitcoinTool.Address

  test "getbalance" do
    {:ok, balance} = :rpc |> Gold.getbalance

    # Make sure Gold is configured for ppcoin
    assert balance.exp == -6
  end

  test "decode raw transaction" do
    txn = Mercator.RPC.gettransaction!("9d4263fdc91aa2bbcdc4f24e4d8296c0045f23362d3cfa5821118d5f1501fafc")
    assert txn.txid == "9d4263fdc91aa2bbcdc4f24e4d8296c0045f23362d3cfa5821118d5f1501fafc"
    assert txn.timestamp > 0
    assert Enum.count(txn.inputs) == 1
    assert Enum.count(txn.outputs) == 2
    second_output = txn.outputs |> Enum.at(1)
    assert second_output.value == 100.0e6
  end

  test "parse address from P2PKH output" do
    address = "76a914c5c3b55e10f1c1380a0ed77c483c77c7ee8bf6a188ac"
    |> script_to_txout
    |> Script.parse_address!

    assert address |> Address.raw == <<197, 195, 181, 94, 16, 241, 193, 56, 10, 14, 215, 124, 72, 60, 119, 199, 238, 139, 246, 161>>
    assert address |> Address.base58check == "myYdruaHPoL2HMm8eSbTtn2kQ8PTuZSoYJ"
  end

  test "parse address from compressed P2PKH input" do
    address = "47304402201668e9ca285d1c53f5e9ce6fcbc8cf7f4f10de195c2d6f62508c8cd4ed6a8b4a0220687154d0f6722d915532d074154fc307d68ce8262c95c89930a4e9afa2502aac0121029ccc974c232080cdb53e4bf40d72c70311b6e0d184edbd9459ce222c4a64f752"
    |> script_to_txin
    |> Script.parse_address!

    assert address |> Address.base58check == "mnnHbwi92SakcQNj8ixRRN4xe5pfmc3oxV"
  end

  test "parse address from uncompressed P2PKH input" do
    address = "483045022100ed64dc0c66c230b2e0e104b4976188d17d818606cdcd0e3e262fb4a8ac0b7c9202207a3dc0dbd55180496f96656079f4fc6fdf30beea889f9d2847f2d3cf45903e570141045d6d4668791141b1cedf149bda8905a5fd3d468ebed4a104748f1a2d0c641a4b18633810318a8170d807437d6c0988d9eb72b64ce364b01615a2a397c2ea788b"
    |> script_to_txin
    |> Script.parse_address!

    assert address |> Address.base58check == "mr9U9teYPd3A3HyPkF6YcvPso4bUzVsZ1a"
  end

  test "parse address from compressed P2PK output" do
    address = "21028152899e9c4ef3739de9d146d0293b5581180d393493e815e57559489631b81eac"
    |> script_to_txout
    |> Script.parse_address!

    assert address |> Address.base58check == "mn1Q6vpuytTKi1yYqxV4z34T2F8BxDrg6a"
  end

  test "parse address from uncompressed P2PK output" do
    address = "41045d6d4668791141b1cedf149bda8905a5fd3d468ebed4a104748f1a2d0c641a4b18633810318a8170d807437d6c0988d9eb72b64ce364b01615a2a397c2ea788bac"
    |> script_to_txout
    |> Script.parse_address!

    assert address |> Address.base58check == "mr9U9teYPd3A3HyPkF6YcvPso4bUzVsZ1a"
  end

  test "parse P2PK input" do
    address = "42cdee67468cc874199e0f9c4ec615a419ed9b9c26fda68e523b63e02d4603890000000049483045022100f315bc9f149995b5120cb69dc8fe3c2a2aa02e7b68c4fe4b63505535710346ad022006d96467a527f2fdfd886b034576da23c9675b29241f78903166a8400f15f61801ffffffff"
    |> Base.decode16!(case: :lower)
    |> TransactionInput.parse_stream
    |> hd
    |> Script.parse_address!

    assert address |> Address.base58check == "mpwRGC6URPCvdU4J83YbUzvqmBhKSDXk4p"
  end

  test "parse data from OP_RETURN output" do
    # length < 76
    short_string = "6a0e612073686f727420737472696e67"
    |> script_to_txout
    |> Script.parse_opreturn!
    assert short_string == "a short string"

    # length > 76 (OP_PUSHDATA1)
    pushdata1_string = "6a4cae4c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73656374657475722061646970697363696e6720656c69742e204e756c6c616d20736f6c6c696369747564696e2c206e657175652073697420616d65742074656d706f72206469676e697373696d2c20746f72746f7220646f6c6f7220616363756d73616e206c6967756c612c20736564206c6163696e6961206e65717565206e6962682076656c20646f6c6f722e"
    |> script_to_txout
    |> Script.parse_opreturn!
    assert pushdata1_string == "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam sollicitudin, neque sit amet tempor dignissim, tortor dolor accumsan ligula, sed lacinia neque nibh vel dolor."

    # length > 255 (OP_PUSHDATA2)
    pushdata2_string = "6a4d88014c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73656374657475722061646970697363696e6720656c69742e204e756c6c616d20736f6c6c696369747564696e2c206e657175652073697420616d65742074656d706f72206469676e697373696d2c20746f72746f7220646f6c6f7220616363756d73616e206c6967756c612c20736564206c6163696e6961206e65717565206e6962682076656c20646f6c6f722e2050686173656c6c7573206964206e69736c2061206a7573746f2076656e656e617469732064696374756d2e20446f6e6563206d65747573206d61757269732c2073656d706572206665756769617420756c7472696365732073697420616d65742c206c616f72656574206e65632070757275732e204e756c6c61206163206e756c6c61206573742e204e756c6c6120666163696c6973692e20566573746962756c756d20696e206d6f6c6c6973206e69736c2e20416c697175616d206d616c6573756164612076656e656e61746973207665686963756c612e"
    |> script_to_txout
    |> Script.parse_opreturn!
    assert pushdata2_string == "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam sollicitudin, neque sit amet tempor dignissim, tortor dolor accumsan ligula, sed lacinia neque nibh vel dolor. Phasellus id nisl a justo venenatis dictum. Donec metus mauris, semper feugiat ultrices sit amet, laoreet nec purus. Nulla ac nulla est. Nulla facilisi. Vestibulum in mollis nisl. Aliquam malesuada venenatis vehicula."
  end

  defp script_to_txout(script_hex) do
    %Bitcoin.Protocol.Types.TransactionOutput{
      pk_script: script_hex |> Base.decode16!(case: :lower)
    }
  end

  defp script_to_txin(script_hex) do
    %Bitcoin.Protocol.Types.TransactionInput{
      signature_script: script_hex |> Base.decode16!(case: :lower)
    }
  end

  test "gettransactions batch call" do
    txns = Mercator.RPC.gettransactions!(["9d4263fdc91aa2bbcdc4f24e4d8296c0045f23362d3cfa5821118d5f1501fafc",
                                         "356b9736ee7dbf387ea7b10a16beda8ea1ad5db0cbc53e749f5e4b3cf7545552",
                                         "8903462de0633b528ea6fd269c9bed19a415c64e9c0f9e1974c88c4667eecd42",
                                         "eeb310fd9c81d786954ec74c491e56daeed39277f7e508a5761865e571730a87"])
    #IO.inspect(txns)
  end
end
