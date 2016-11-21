defmodule Mercator.PeerAssets.Types.DeckSpawn do
  use Bitwise

  alias Bitcoin.Protocol.Types.Script
  alias Mercator.PeerAssets.Protobufs
  alias BitcoinTool.Address
  alias Mercator.PeerAssets.Protobufs.DeckSpawn.MODE

  defstruct asset_id: nil,
            owner_address: nil,
            tag_address: nil,
            issue_modes: nil,
            number_of_decimals: nil,
            short_name: nil,
            asset_specific_data: nil

  def parse_txn(txn) do
    try do
      {:ok, parse_txn!(txn)}
    catch
      _, err -> {:error, err}
    end
  end

  def parse_txn!(txn) do
    [owner_input | _] = txn.inputs
    [p2th_output, pa_data_output | _] = txn.outputs

    # Parse the first input (from owner address)
    owner_address = owner_input
    |> Script.parse_address! # throws on parse failure
    |> Address.base58check

    # Parse the first output (P2TH)
    p2th_address = p2th_output
    |> Script.parse_address! # throws on parse failure
    |> Address.base58check

    # Parse the second output (OP_RETURN PeerAssets data)
    pa_data = pa_data_output
    |> Script.parse_opreturn! # throws on parse failure
    |> Protobufs.DeckSpawn.decode

    %Mercator.PeerAssets.Types.DeckSpawn{
      asset_id: txn.txid,
      owner_address: owner_address,
      tag_address: p2th_address,
      issue_modes: parse_modes!(pa_data.issue_mode),
      number_of_decimals: pa_data.number_of_decimals,
      short_name: pa_data.short_name,
      asset_specific_data: pa_data.asset_specific_data
    }
  end

  defp parse_modes!(issue_mode) do
    for mode <- MODE.atoms, (issue_mode &&& MODE.value(mode)) > 0, do: mode
  end
end
