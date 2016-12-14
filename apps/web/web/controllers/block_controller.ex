defmodule Mercator.Web.BlockController do
  use Mercator.Web.Web, :controller

  import Plug.Conn

  def info(conn, %{"height" => height}) do
    {height, _} = Integer.parse(height)

    hash = :rpc
    |> Gold.getblockhash!(height)

    response = :rpc
    |> Gold.getblock!(hash)
    |> Poison.encode!

    conn |> send_resp(200, response)
  end

end
