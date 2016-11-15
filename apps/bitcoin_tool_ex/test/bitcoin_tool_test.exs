defmodule BitcoinToolTest do
  use ExUnit.Case
  doctest BitcoinTool

  alias BitcoinTool.Protocols.Address

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

    assert result |> Address.base58check == "PRoUKDUhA1vgBseJCaGMd9AYXdQcyEjxu9"
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

    assert result |> Address.base58check == "mxjFTJApv7sjz9T9a4vCnAQbmsqSoL8VWo"
    assert result.private_key_wif_base58check == "cU6CjGw3mRmirjiUZfRkJ1aj2D493k7uuhywj6tCVbLAMABy4MwU"
  end

  test "Uncompressed key generation" do
    BitcoinTool.start_link(:uncompressed_key_test,
      %BitcoinTool.Config{
        input_type: "private-key",
        input_format: "hex",
        public_key_compression: "uncompressed",
        network: "peercoin"
      }
    )

    result =
    "c23375caa1ba3b0eec3a49fff5e008dede0c2761bb31fddd830da32671c17f84"
    |> BitcoinTool.process!(:uncompressed_key_test)

    assert result |> Address.base58check == "PDy6F71ApMcSB9GkCgzcoNfxewYLwq8QkX"
    assert result.private_key_wif_base58check == "7ACktV3C6PzKsUBXVeEJqKR7pKm6HA3mMqWNcVf3GMsbLtjziHw"
  end

  test "Generate from public key" do
    BitcoinTool.start_link(:public_key_test,
      %BitcoinTool.Config{
        input_type: "public-key",
        input_format: "hex",
        public_key_compression: "compressed",
        network: "peercoin"
      }
    )

    address =
    "02b239c40dddff9c5ba613bcc9b40a858fec8b5b9097c0ed2dd7ee799b17aab1e7"
    |> BitcoinTool.process!(:public_key_test)
    |> Address.base58check

    assert address == "PRoUKDUhA1vgBseJCaGMd9AYXdQcyEjxu9"
  end

  test "Generate from WIF" do
    BitcoinTool.start_link(:private_key_wif_test,
      %BitcoinTool.Config{
        input_type: "private-key-wif",
        input_format: "base58check",
        public_key_compression: "uncompressed",
        network: "peercoin"
      }
    )

    address =
    "7A6cFXZSZnNUzutCMcuE1hyqDPtysH2LrSA9i5sqP2BPCLrAvZM"
    |> BitcoinTool.process!(:private_key_wif_test)
    |> Address.base58check

    assert address == "PAprodpH5y2YuJFHFCXWRuVzZNr7Tw78sV"
  end

  test "Generate from hex address" do
    BitcoinTool.start_link(:address_test,
      %BitcoinTool.Config{
        input_type: "address",
        input_format: "hex",
        public_key_compression: "uncompressed",
        network: "peercoin"
      }
    )

    address =
    "371886c1b6001b8ea23106a08f0d3b640e8497afc7"
    |> BitcoinTool.process!(:address_test)
    |> Address.base58check

    assert address == "PAprodpH5y2YuJFHFCXWRuVzZNr7Tw78sV"
  end

  test "Should raise error on invalid input" do
    assert_raise BitcoinToolError, fn ->
      BitcoinTool.start_link(:error_test, %BitcoinTool.Config{input_format: "hex", network: "peercoin"})
      "hello" # is not hexadecimal
      |> BitcoinTool.process!(:error_test)
    end
  end

  test "Address.from_pkh" do
    hex = "70ca5c06a6b9a47423887043b842e6d93fd49056"
    pkh = hex |> Base.decode16!(case: :lower)
    address = pkh |> BitcoinTool.Address.from_pkh(%BitcoinTool.Config{network: "peercoin"})

    assert address |> Address.raw == pkh
    assert address |> Address.hex == hex
    assert address |> Address.base58check == "PJsZFe8kFmzBoq5svmfZ9pcGMQ2zDpPpDR"
  end
end
