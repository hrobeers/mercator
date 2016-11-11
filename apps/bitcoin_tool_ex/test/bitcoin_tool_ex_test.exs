defmodule BitcoinToolTest do
  use ExUnit.Case
  doctest BitcoinTool

  test "P2TH peercoin test vector" do
    BitcoinTool.start_link(:p2th_test,
      %BitcoinTool.Config{
        input_type: "private-key",
        input_format: "hex",
        network: "peercoin"
      }
    )

    result =
    "c23375caa1ba3b0eec3a49fff5e008dede0c2761bb31fddd830da32671c17f84"
    |> BitcoinTool.process!(:p2th_test)

    assert result.address_base58check == "PRoUKDUhA1vgBseJCaGMd9AYXdQcyEjxu9"
    assert result.private_key_wif_base58check == "UBctiEkfxpU2HkyTbRKjiGHT5socJJwCny6ePfUtzo8Jad9wVzeA"
  end

  test "P2TH peercoin-testnet test vector" do
    BitcoinTool.start_link(:p2th_testnet_test,
      %BitcoinTool.Config{
        input_type: "private-key",
        input_format: "hex",
        network: "peercoin-testnet"
      }
    )

    result =
    "c23375caa1ba3b0eec3a49fff5e008dede0c2761bb31fddd830da32671c17f84"
    |> BitcoinTool.process!(:p2th_testnet_test)

    assert result.address_base58check == "mxjFTJApv7sjz9T9a4vCnAQbmsqSoL8VWo"
    assert result.private_key_wif_base58check == "cU6CjGw3mRmirjiUZfRkJ1aj2D493k7uuhywj6tCVbLAMABy4MwU"
  end

  test "Should raise error on invalid input" do
    assert_raise BitcoinToolError, fn ->
      BitcoinTool.start_link(:error_test, %BitcoinTool.Config{input_format: "hex"})
      "hello" # is not hexadecimal
      |> BitcoinTool.process!(:error_test)
    end
  end
end
