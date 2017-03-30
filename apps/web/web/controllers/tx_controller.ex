defmodule Mercator.Web.TxController do
  use Mercator.Web.Web, :controller

  import Plug.Conn

  def push(conn, %{"hex" => rawtx}) do
    case :rpc |> Gold.sendrawtransaction(rawtx) do
      {:ok, txid} ->
        conn |> send_resp(200, txid)
      :internal_server_error ->
        conn |> send_resp(500, "Transaction rejected")
      _ ->
        conn |> send_resp(500, "Unkown error occured")
    end
  end

  def push(conn, _) do
    conn |> send_resp(400, "Expected format: {\"hex\":\"RAW_TX\"}")
  end

end
