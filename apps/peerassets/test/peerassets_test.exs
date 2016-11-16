defmodule Mercator.PeerAssetsTest do
  use ExUnit.Case
  doctest Mercator.PeerAssets

  alias Mercator.PeerAssets.Repo
  alias Bitcoin.Protocol.Types.Script
  alias Mercator.PeerAssets.Protobufs
  alias BitcoinTool.Address

  test "P2TH import" do
    Application.get_env(:peerassets, :PAprod)
    |> Repo.load_tag! # throws on failure

    Application.get_env(:peerassets, :PAtest)
    |> Repo.load_tag! # throws on failure

    # Assert error thrown on failure
    assert_raise MatchError, fn ->
      %{label: "PAprod",
        address: "invalid address",
        wif: "invalid wif"}
      |> Repo.load_tag!
    end
  end

  test "Decode deck spawn txn" do
    # Decoding the PeerAssets challenge transaction: https://www.peercointalk.org/index.php?topic=4760.0
    txn = Mercator.RPC.gettransaction!("356b9736ee7dbf387ea7b10a16beda8ea1ad5db0cbc53e749f5e4b3cf7545552")

    [owner_input] = txn.inputs
    [p2th_output, pa_data_output, _] = txn.outputs

    # Parse the first input (from owner address)
    owner_address = owner_input
    |> Script.parse_address! # throws on parse failure
    |> Address.base58check
    assert owner_address == "mpwRGC6URPCvdU4J83YbUzvqmBhKSDXk4p"

    # Parse the first output (P2TH)
    p2th_address = p2th_output
    |> Script.parse_address! # throws on parse failure
    |> Address.base58check
    assert p2th_address == "mwqncWSnzUzouPZcLQWcLTPuSVq3rSiAAa" # PAtest address on testnet

    # Parse the second output (OP_RETURN PeerAssets data)
    pa_data = pa_data_output
    |> Script.parse_opreturn! # throws on parse failure
    |> Protobufs.DeckSpawn.decode
    assert pa_data.version == 1
    assert pa_data.issue_mode == 10
    assert pa_data.number_of_decimals == 2
    assert pa_data.short_name == "hrobeers owes you 100PPC, real ones!" # Sorry, it's claimed by saeveritt
    assert pa_data.asset_specific_data == nil
  end
end
