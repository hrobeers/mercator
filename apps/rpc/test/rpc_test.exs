defmodule Mercator.RPCTest do
  use ExUnit.Case
  doctest Mercator.RPC

  alias Bitcoin.Protocol.Types.Script
  alias BitcoinTool.Protocols.Address

  test "getbalance" do
    {:ok, balance} = :rpc |> Gold.getbalance

    # Make sure Gold is configured for ppcoin
    assert balance.exp == -6
  end

  test "decode raw transaction" do
    txn = Mercator.RPC.gettransaction!("9d4263fdc91aa2bbcdc4f24e4d8296c0045f23362d3cfa5821118d5f1501fafc")
    assert txn.timestamp > 0
    assert Enum.count(txn.inputs) == 1
    assert Enum.count(txn.outputs) == 2
    second_output = txn.outputs |> Enum.at(1)
    assert second_output.value == 100.0e6
  end

  test "parse P2PKH output script" do
    result = "76a914c5c3b55e10f1c1380a0ed77c483c77c7ee8bf6a188ac"
    |> Base.decode16!(case: :lower)
    |> Script.parse_p2pkh!
    |> BitcoinTool.Address.from_pkh(%BitcoinTool.Config{network: "peercoin"})

    assert result.raw == <<197, 195, 181, 94, 16, 241, 193, 56, 10, 14, 215, 124, 72, 60, 119, 199, 238, 139, 246, 161>>
    assert result |> Address.base58check == "PScript9dhNxV5xHGwwcjknh9sxe6s4tVX"
  end

  test "parse OP_RETURN output scripts" do
    # length < 76
    short_string = "6a0e612073686f727420737472696e67"
    |> Base.decode16!(case: :lower)
    |> Script.parse_opreturn!
    assert short_string == "a short string"

    # length > 76 (OP_PUSHDATA1)
    pushdata1_string = "6a4cae4c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73656374657475722061646970697363696e6720656c69742e204e756c6c616d20736f6c6c696369747564696e2c206e657175652073697420616d65742074656d706f72206469676e697373696d2c20746f72746f7220646f6c6f7220616363756d73616e206c6967756c612c20736564206c6163696e6961206e65717565206e6962682076656c20646f6c6f722e"
    |> Base.decode16!(case: :lower)
    |> Script.parse_opreturn!
    assert pushdata1_string == "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam sollicitudin, neque sit amet tempor dignissim, tortor dolor accumsan ligula, sed lacinia neque nibh vel dolor."

    # length > 255 (OP_PUSHDATA2)
    pushdata2_string = "6a4d88014c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73656374657475722061646970697363696e6720656c69742e204e756c6c616d20736f6c6c696369747564696e2c206e657175652073697420616d65742074656d706f72206469676e697373696d2c20746f72746f7220646f6c6f7220616363756d73616e206c6967756c612c20736564206c6163696e6961206e65717565206e6962682076656c20646f6c6f722e2050686173656c6c7573206964206e69736c2061206a7573746f2076656e656e617469732064696374756d2e20446f6e6563206d65747573206d61757269732c2073656d706572206665756769617420756c7472696365732073697420616d65742c206c616f72656574206e65632070757275732e204e756c6c61206163206e756c6c61206573742e204e756c6c6120666163696c6973692e20566573746962756c756d20696e206d6f6c6c6973206e69736c2e20416c697175616d206d616c6573756164612076656e656e61746973207665686963756c612e"
    |> Base.decode16!(case: :lower)
    |> Script.parse_opreturn!
    assert pushdata2_string == "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam sollicitudin, neque sit amet tempor dignissim, tortor dolor accumsan ligula, sed lacinia neque nibh vel dolor. Phasellus id nisl a justo venenatis dictum. Donec metus mauris, semper feugiat ultrices sit amet, laoreet nec purus. Nulla ac nulla est. Nulla facilisi. Vestibulum in mollis nisl. Aliquam malesuada venenatis vehicula."
  end
end
