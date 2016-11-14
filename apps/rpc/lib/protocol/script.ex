defmodule Bitcoin.Protocol.Types.Script do

  def parse_p2pkh(script) do
    case script do
      <<118, 169, 20, pkh :: bytes-size(20), 136, 172>> ->
        {:ok, pkh}
      _ ->
        {:error, "Not a P2PKH script"}
    end
  end

  def parse_p2pkh!(script) do
    case parse_p2pkh(script) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end

end
