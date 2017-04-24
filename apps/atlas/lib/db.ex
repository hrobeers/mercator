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

  defp db_dir() do
    case Application.get_env(:atlas, :db_dir) do
      nil -> :no_db
      path -> {:ok, path}
    end
  end

  ## Client API

  def add_input(txn, prev_out) do
    txn_key = txn.txn_id <> varint(txn.idx)
    prev_out |> mark_spent(txn_key)
  end

  def add_output(output, idx, txn, block) do
    output_key = txn.txn_id <> varint(idx)
    if not is_spent?(output_key) do
      false |> store(output_key, :unspent)
    end
    add_inoutput(output, varint(block.height) <> varint(txn.idx) <> varint(idx)) # TODO txn_key -> output_key
  end

  def list_outputs(pkh) do
    pkh
    |> retrieve(:address_index)
    |> Enum.uniq # TODO investigate why doubles
  end

  def persist!() do
    persist!(db_dir())
  end

  ## Internal

  def init(start_height) do
    init(start_height, db_dir())
  end

  defp init(start_height, {:ok, db}) do
    db = db |> String.to_charlist
    if File.exists?(db) do
      # TODO log warning or error on failure & improve robustness
      {:ok, :spent} = :filename.join(db, 'spent.ets') |> :ets.file2tab()
      {:ok, :unspent} = :filename.join(db, 'unspent.ets') |> :ets.file2tab()
      {:ok, :op_return} = :filename.join(db, 'op_return.ets') |> :ets.file2tab()
      {:ok, :address_index} = :filename.join(db, 'address_index.ets') |> :ets.file2tab()
      retrieve(:low_cnt, :address_index) |> IO.inspect
      retrieve(:high_cnt, :address_index) |> IO.inspect

      :ets.new(:unconfirmed, [:set, :protected, :named_table])
      #:ets.new(:blocks, [:set, :protected, :named_table])
    else
      init(start_height, :no_db)
    end
    :ok
  end
  defp init(start_height, :no_db) do
    # TODO consider :bag & :ordered_set for tables (compare size & performance)
    :ets.new(:address_index, [:set, :public, :named_table])
    :ets.new(:op_return, [:set, :public, :named_table])
    :ets.new(:spent, [:set, :public, :named_table])
    :ets.new(:unspent, [:set, :public, :named_table])
    # Set initial parsing state
    store(start_height, :low_cnt, :address_index)
    store(start_height, :high_cnt, :address_index)

    :ets.new(:unconfirmed, [:set, :protected, :named_table])
    #:ets.new(:blocks, [:set, :protected, :named_table])

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

  defp persist!({:ok, db}) do
    # Ignore error if already exists
    db |> File.mkdir()
    # Backup previous
    db
    |> File.ls!()
    |> Enum.filter(&(&1 |> String.ends_with?(".bak") == false))
    |> Enum.each(&(File.rename(Path.join(db, &1), Path.join(db, &1 <> ".bak"))))
    # Save to disk
    # TODO log warning or error on failure
    :ok = :spent |> :ets.tab2file(Path.join(db, 'spent.ets'))
    :ok = :unspent |> :ets.tab2file(Path.join(db, 'unspent.ets'))
    :ok = :op_return |> :ets.tab2file(Path.join(db, 'op_return.ets'))
    :ok = :address_index |> :ets.tab2file(Path.join(db, 'address_index.ets'))
  end
  defp persist!(:no_db) do
    # Do nothing
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
      _tx_key -> # TODO are we interested in tx_key?
        output_key |> delete(:spent)
        true
    end
  end

  defp add_inoutput({:address, pkh}, output_key) do
    [output_key | retrieve(pkh, :address_index)]
    |> store(pkh, :address_index)
  end
  defp add_inoutput({:op_return, data}, output_key) do
    :op_return |> :ets.insert({output_key, data})
  end
  defp add_inoutput({:coinbase, _script}, _output_key), do: nil
  defp add_inoutput({:empty}, _output_key), do: nil
  defp add_inoutput({:error, reason, inoutput}, output_key) do
    # TODO: decode output_key
    Logger.error """
Atlas: #{reason}:
  output_key: #{output_key}
  #{inspect(inoutput)}
"""
  end
end
