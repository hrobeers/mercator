defmodule Mercator.PeerAssetsTest do
  use ExUnit.Case
  doctest Mercator.PeerAssets

  alias Mercator.PeerAssets.Repo

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
end
