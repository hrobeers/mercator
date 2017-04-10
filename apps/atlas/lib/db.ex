require Logger

defmodule Mercator.Atlas.DB do
  @moduledoc"""
  Module providing DB access functions.
  All code is executed in calling process.
  """

  def init() do
    :ets.new(:pkh_index, [:set, :public, :named_table])
    :ets.new(:sh_index, [:set, :public, :named_table])
    :ets.new(:op_return, [:set, :public, :named_table])
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

  def add_input(input, txn, block) do
    # forward to add_output
    add_output(input, txn, block)
  end

  def add_output({:pkh, pkh}, txn, block) do
    #txn_id = txn.txn_id |> Base.decode16!(case: :lower)
    #[{txn_id, block.hash} | retrieve(pkh, :pkh_index)]
    block_height = :gpb.encode_varint(block.height)
    txn_idx = :gpb.encode_varint(txn.idx)
    [block_height <> txn_idx | retrieve(pkh, :pkh_index)]
    |> store(pkh, :pkh_index)
  end
  def add_output({:sh, sh}, txn, block) do
    #txn_id = txn.txn_id |> Base.decode16!(case: :lower)
    #[{txn_id, block.hash} | retrieve(sh, :sh_index)]
    block_height = :gpb.encode_varint(block.height)
    txn_idx = :gpb.encode_varint(txn.idx)
    [block_height <> txn_idx | retrieve(sh, :sh_index)]
    |> store(sh, :sh_index)
  end
  def add_output({:op_return, data}, txn, block) do
    #txn_id = txn.txn_id |> Base.decode16!(case: :lower)
    #:op_return |> :ets.insert({txn_id, block.hash, %{height: block.height, data: data}})
    block_height = :gpb.encode_varint(block.height)
    txn_idx = :gpb.encode_varint(txn.idx)
    :op_return |> :ets.insert({block_height <> txn_idx, data})
  end
  def add_output({:coinbase, _script}, _txn, _block), do: nil
  def add_output({:empty}, _txn, _block), do: nil
  def add_output({:error, reason, inoutput}, txn, _block) do
    Logger.error """
Atlas: #{reason}:
  txn_id: #{txn.txn_id}
  #{inspect(inoutput)}
"""
  end
end
