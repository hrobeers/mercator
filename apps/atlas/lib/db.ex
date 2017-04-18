require Logger

defmodule Mercator.Atlas.DB do
  @moduledoc"""
  Module providing DB access functions.
  All code is executed in calling process.
  """

  alias Bitcoin.Protocol.Types.Outpoint

  defmacro varint(i) do
    quote do
      :gpb.encode_varint(unquote(i))
    end
  end

  def init() do
    :ets.new(:pkh_index, [:set, :public, :named_table])
    :ets.new(:sh_index, [:set, :public, :named_table])
    :ets.new(:op_return, [:set, :public, :named_table])
    :ets.new(:spent, [:set, :public, :named_table])
    :ets.new(:unspent, [:set, :public, :named_table])
    :ets.new(:unconfirmed, [:set, :protected, :named_table])
    :ets.new(:blocks, [:set, :protected, :named_table])
    :ok
  end

  def retrieve(key, table) do
    case :ets.lookup(table, key) do
      [{_key, result}] -> result
      [] -> []
    end
  end

  def store(value, key, table) do
    table
    |> :ets.insert({key, value})
  end

  def delete(key, table) do
    :ets.delete(table, key)
  end

  def add_input(input, idx, txn, block, prev_out) do
    # TODO mark spent
    txn_key = txn.txn_id <> varint(txn.idx)
    prev_out |> mark_spent(txn_key)
    #add_inoutput(input, txn_key)
  end

  def add_output(output, idx, txn, block) do
    txn_key = varint(block.height) <> varint(txn.idx)
    output_key = txn.txn_id <> varint(idx)
    if not is_spent?(output_key) do
      false |> store(output_key, :unspent)
    end
    add_inoutput(output, txn_key)
  end

  defp mark_spent(%Outpoint{hash: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>},_) do
    # ignore
  end
  defp mark_spent(outpoint, txn_key) do
    # outpoint is reversed!
    prev_hash = outpoint.hash |> :binary.bin_to_list |> :lists.reverse |> :binary.list_to_bin
    prev_out_key = prev_hash <> varint(outpoint.index)

    case prev_out_key |> retrieve(:unspent) do
      [] -> txn_key |> store(prev_out_key, :spent)
      _ -> prev_out_key |> delete(:unspent)
    end
  end

  defp is_spent?(output_key) do
    case output_key |> retrieve(:spent) do
      [] -> false
      tx_key ->
        output_key |> delete(:spent)
        true
    end
  end

  defp add_inoutput({:pkh, pkh}, txn_key) do
    [txn_key | retrieve(pkh, :pkh_index)]
    |> store(pkh, :pkh_index)
  end
  defp add_inoutput({:sh, sh}, txn_key) do
    [txn_key | retrieve(sh, :sh_index)]
    |> store(sh, :sh_index)
  end
  defp add_inoutput({:op_return, data}, txn_key) do
    :op_return |> :ets.insert({txn_key, data})
  end
  defp add_inoutput({:coinbase, _script}, _txn_key), do: nil
  defp add_inoutput({:empty}, _txn_key), do: nil
  defp add_inoutput({:error, reason, inoutput}, txn_key) do
    # TODO: decode txn_key
    Logger.error """
Atlas: #{reason}:
  txn_key: #{txn_key}
  #{inspect(inoutput)}
"""
  end
end
