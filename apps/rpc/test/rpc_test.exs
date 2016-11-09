defmodule Mercator.RPCTest do
  use ExUnit.Case
  doctest Mercator.RPC

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
end
