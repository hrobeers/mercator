defmodule Mercator.Web.AddressController do
  use Mercator.Web.Web, :controller

  alias Mercator.Atlas.Repo

  import Plug.Conn

  # get "/unspent/:address", AddressController, :unspent
  # get "/balance/:address", AddressController, :balance

  def unspent(conn, %{"address" => address}) do
    unspent = address
    |> BitcoinTool.RawAddress.from_address!()
    |> Mercator.Atlas.Repo.list_unspent!

    conn |> send_resp(200, unspent |> Poison.encode!())
  end

  def balance(conn, %{"address" => address}) do
    balance = address
    |> BitcoinTool.RawAddress.from_address!()
    |> Mercator.Atlas.Repo.balance!

    conn |> send_resp(200, balance |> Poison.encode!())
  end

end
