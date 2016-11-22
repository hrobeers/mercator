defmodule Mercator.Web.PageControllerTest do
  use Mercator.Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Mercator PeerAssets Explorer"
  end
end
