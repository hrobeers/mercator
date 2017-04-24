defmodule Mercator.Web.BlockControllerTest do
  use Mercator.Web.ConnCase

  test "GET /api/unstable/block/info", %{conn: conn} do
    conn = get conn, "/api/unstable/block/info/12321"
    decoded = conn.resp_body |> Poison.decode!

    assert decoded["height"] == 12321
    assert decoded["hash"] == "000000000222939c79dfba0ff255d3ed08b1712e9419c2c2f5c5664602f7e34a"
    assert decoded["previousblockhash"] == "0000000081e380b28634b33e143c90636ab5d27c75c5e5c44c3d59d2bea39539"
    assert decoded["time"] == "2012-10-26 13:23:48 UTC"
    assert decoded["txns"] == ["eeb310fd9c81d786954ec74c491e56daeed39277f7e508a5761865e571730a87"]
  end
end
