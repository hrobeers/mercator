defmodule BitcoinToolTest do
  use ExUnit.Case
  doctest BitcoinTool

  test "Should raise error on invalid input" do
    assert_raise BitcoinToolError, fn ->
      BitcoinTool.start_link(:btctool, %BitcoinTool.Config{input_format: "hex"})
      "hello" # is not hexadecimal
      |> BitcoinTool.process!(:btctool)
    end
  end
end
