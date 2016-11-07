defmodule Mercator.RPCTest do
  use ExUnit.Case
  doctest Mercator.RPC

  test "getbalance" do
    {:ok, balance} = :rpc |> Gold.getbalance

    # Make sure Gold is configured for ppcoin
    assert balance.exp == -6
  end
end
