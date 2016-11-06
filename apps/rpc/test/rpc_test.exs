defmodule Mercator.RPCTest do
  use ExUnit.Case
  doctest Mercator.RPC

  test "getbalance" do
    {:ok, _} = :rpc |> Gold.getbalance
  end
end
