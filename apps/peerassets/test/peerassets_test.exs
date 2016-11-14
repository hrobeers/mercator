defmodule Mercator.PeerAssetsTest do
  use ExUnit.Case
  doctest Mercator.PeerAssets

  alias Mercator.PeerAssets.Repo
  alias Bitcoin.Protocol.Types.Script

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
    txn = Mercator.RPC.gettransaction!("356b9736ee7dbf387ea7b10a16beda8ea1ad5db0cbc53e749f5e4b3cf7545552")
    # Assert this can be a deck spawn txn
    assert txn.outputs |> Enum.count > 2

    # Parse the first output (P2TH)
    txn.outputs
    |> Enum.at(0)
    |> Map.get(:pk_script)
    |> Script.parse_p2pkh! # throws on parse failure
  end
end
