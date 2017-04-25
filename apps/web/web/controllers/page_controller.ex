defmodule Mercator.Web.PageController do
  use Mercator.Web.Web, :controller

  alias Mercator.PeerAssets
  alias Mercator.Atlas

  def index(conn, _params) do
    {:ok, assets_prod} = PeerAssets.Repo.list_assets
    {:ok, assets_test} = PeerAssets.Repo.list_assets :PAtest
    conn |> render("index.html", %{ assets_prod: assets_prod,
                                    assets_test: assets_test })
  end

  def atlas(conn, %{"address" => address}) do
    unspent = address
    |> BitcoinTool.RawAddress.from_address!()
    |> Mercator.Atlas.Repo.list_unspent!
    balance = unspent
    |> Mercator.Atlas.Repo.balance!
    conn |> render("atlas.html", %{address: address, unspent: unspent, balance: balance})
  end
  def atlas(conn, _) do
    unspent = []
    conn |> render("atlas.html", %{address: nil, unspent: unspent, balance: nil})
  end

end
