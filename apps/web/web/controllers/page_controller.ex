defmodule Mercator.Web.PageController do
  use Mercator.Web.Web, :controller

  alias Mercator.PeerAssets.Repo

  def index(conn, _params) do
    {:ok, assets_prod} = Repo.list_assets
    {:ok, assets_test} = Repo.list_assets :PAtest
    conn |> render("index.html", %{ assets_prod: assets_prod,
                                    assets_test: assets_test })
  end
end
