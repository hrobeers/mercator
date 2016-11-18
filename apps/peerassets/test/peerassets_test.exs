defmodule Mercator.PeerAssetsTest do
  use ExUnit.Case
  doctest Mercator.PeerAssets

  alias Mercator.PeerAssets.Repo
  alias Mercator.PeerAssets.Types.DeckSpawn

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

    deck_spawn = txn |> DeckSpawn.parse_txn!

    assert deck_spawn.owner_address == "mpwRGC6URPCvdU4J83YbUzvqmBhKSDXk4p"
    assert deck_spawn.tag_address == "mwqncWSnzUzouPZcLQWcLTPuSVq3rSiAAa" # PAtest address on testnet

    assert deck_spawn.issue_modes == [:ONCE] # originally [:ONCE, :PEG] but PEG is removed from spec
    assert deck_spawn.number_of_decimals == 2
    assert deck_spawn.short_name == "hrobeers owes you 100PPC, real ones!" # Sorry, it's claimed by saeveritt
    assert deck_spawn.asset_specific_data == nil
  end
end
