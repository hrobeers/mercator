require Logger

defmodule Mercator.Atlas.DB do
  @moduledoc"""
  Module providing DB access functions.
  All code is executed in calling process.
  """

  defmacro varint(i) do
    quote do
      :gpb.encode_varint(unquote(i))
    end
  end

  def init() do
    :ets.new(:pkh_index, [:set, :public, :named_table])
    :ets.new(:sh_index, [:set, :public, :named_table])
    :ets.new(:op_return, [:set, :public, :named_table])
    :ets.new(:outputs, [:set, :public, :named_table])
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

  def add_input({input, idx}, txn, block) do
    # TODO mark spent
    add_inoutput(input, txn, block)
  end

  def add_output({output, idx}, txn, block) do
    output_key = varint(block.height) <> varint(txn.idx) <> varint(idx)
    spent_by(txn.txn_id, idx)
    |> store(output_key, :outputs)
    add_inoutput(output, txn, block)
  end

  defp spent_by(txn_id, output_idx) do
    key = txn_id <> varint(output_idx)
    case key |> retrieve(:outputs) do
      [] -> false
      tx_key ->
        key |> delete(:outputs)
        tx_key
    end
  end

  defp add_inoutput({:pkh, pkh}, txn, block) do
    #txn_id = txn.txn_id |> Base.decode16!(case: :lower)
    #[{txn_id, block.hash} | retrieve(pkh, :pkh_index)]
    block_height = varint(block.height)
    txn_idx = varint(txn.idx)
    [block_height <> txn_idx | retrieve(pkh, :pkh_index)]
    |> store(pkh, :pkh_index)
  end
  defp add_inoutput({:sh, sh}, txn, block) do
    #txn_id = txn.txn_id |> Base.decode16!(case: :lower)
    #[{txn_id, block.hash} | retrieve(sh, :sh_index)]
    block_height = varint(block.height)
    txn_idx = varint(txn.idx)
    [block_height <> txn_idx | retrieve(sh, :sh_index)]
    |> store(sh, :sh_index)
  end
  defp add_inoutput({:op_return, data}, txn, block) do
    #txn_id = txn.txn_id |> Base.decode16!(case: :lower)
    #:op_return |> :ets.insert({txn_id, block.hash, %{height: block.height, data: data}})
    block_height = varint(block.height)
    txn_idx = varint(txn.idx)
    :op_return |> :ets.insert({block_height <> txn_idx, data})
  end
  defp add_inoutput({:coinbase, _script}, _txn, _block), do: nil
  defp add_inoutput({:empty}, _txn, _block), do: nil
  defp add_inoutput({:error, reason, inoutput}, txn, _block) do
    Logger.error """
Atlas: #{reason}:
  txn_id: #{txn.txn_id}
  #{inspect(inoutput)}
"""
  end
end
