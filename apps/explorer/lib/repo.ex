defmodule Mercator.Explorer.Repo do
  use GenServer
  require Logger

  alias Bitcoin.Protocol.Types.Script
  alias BitcoinTool.Address
  alias Mercator.RPC

  defp reload_interval, do: 20*1000 # TODO from config

  @tasksup_name String.to_atom(Atom.to_string(__MODULE__) <> ".TaskSup")

  ## Client API

  @doc """
  Starts the Explorer repository.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  ## Server Callbacks

  def init(:ok) do
    # init the Repo
    init(:retry, true)
  end

  defp init(:retry, log) do
    try do
      # Check the connection
      block_cnt = :rpc |> Gold.getblockcount!
      Logger.info("Explorer.Repo: RPC connection initialized (reload_interval: " <> Integer.to_string(reload_interval) <> ")")
      # Init the ETS tables
      :ets.new(:pkh_index, [:set, :public, :named_table])
      :ets.new(:sh_index, [:set, :public, :named_table])
      :ets.new(:op_return, [:set, :public, :named_table])
      # Set initial parsing state
      store(0, :low_cnt, :pkh_index)
      store(0, :high_cnt, :pkh_index)
      # Init the task supervisor
      Task.Supervisor.start_link(name: @tasksup_name)
      # Initial blockchain parse (TODO: persistent storage)
      parse_new_blocks(1)
      {:ok, %{connected: true, parsing: false, start_time: DateTime.to_unix(DateTime.utc_now)}}
    rescue
      _ ->
        if log, do: Logger.warn("Explorer.Repo: Failed to establish rpc connection. Will retry every second.")
        # Block synchronously until connection is established
        :timer.sleep(1000)
        init(:retry, false)
    end
  end

  defp parse_new_blocks(timeout) do
    Process.send_after(self(), :parse_new, timeout)
  end
  def handle_info(:parse_new, state) do
    new_state =
      case :rpc |> Gold.getblockcount do
        {:ok, block_cnt} ->
          # Log reconnection if wasn't connected
          unless Map.get(state, :connected), do: Logger.info("Explorer.Repo: rpc connection re-established")
          state = state |> Map.put(:connected, true)

          # Parse new blocks when they arrived
          high_cnt = retrieve(:high_cnt, :pkh_index)
          cond do
            high_cnt == block_cnt -> Logger.info("Explorer.Repo: up to date")
            state.parsing == false -> parse_blocks!(high_cnt, block_cnt)
            true -> nil
          end

          # Return state
          state
        {:error, _} ->
          # TODO: log error
          if Map.get(state, :connected), do: Logger.warn("PeerAssets.Repo: rpc connection lost")
          state |> Map.put(:connected, false)# no connection, just ignore until restored
      end

    parse_new_blocks(reload_interval)
    {:noreply, new_state}
  end

  def handle_info({_ref, %{height: height} }, state) do
    # TODO register parsed block height
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    # ignore
    {:noreply, state}
  end

  def handle_cast({:parse_blocks, block, low, high}, state) do
    if (high-low > 1000) do
      range = Integer.to_string(low) <> " - " <> Integer.to_string(high)
      progress = Float.to_string(Float.round((high-block.height)/(high-low)*100, 2)) <> "%"
      Logger.info("Explorer.Repo: Parsing blocks in range: " <> range <> " progress: " <> progress)
    end
    block |> parse_blocks!(low, high)
    {:noreply, state |> Map.put(:parsing, true)}
  end

  def handle_cast({:parsing_done, low, high}, state) do
    if (high-low > 1000) do
      range = Integer.to_string(low) <> " - " <> Integer.to_string(high)
      Logger.info("Explorer.Repo: Parsing blocks in range: " <> range <> " progress: 100%")
    end

    high |> store(:high_cnt, :pkh_index)
    {:noreply, state |> Map.put(:parsing, false)}
  end

  ## Private

  defp retrieve(key, table) do
    case :ets.lookup(table, key) do
      [{_key, result}] -> result
      [] -> []
    end
  end

  defp store(value, key, table) do
    table
    |> :ets.insert({key, value})
  end

  defp add_to_db({:pkh, pkh}, txn_id) do
    txn_id = txn_id |> Base.decode16!(case: :lower)
    [txn_id | retrieve(pkh, :pkh_index)]
    |> store(pkh, :pkh_index)
  end
  defp add_to_db({:sh, sh}, txn_id) do
    txn_id = txn_id |> Base.decode16!(case: :lower)
    [txn_id | retrieve(sh, :sh_index)]
    |> store(sh, :sh_index)
  end
  defp add_to_db({:op_return, data}, txn_id) do
    txn_id = txn_id |> Base.decode16!(case: :lower)
    :op_return |> :ets.insert({txn_id, data})
  end
  defp add_to_db({:coinbase, _script}, _txn_id), do: nil
  defp add_to_db({:empty}, _txn_id), do: nil
  defp add_to_db({:error, reason, inoutput}, txn_id) do
    Logger.error """
Explorer: #{reason}:
  txn_id: #{txn_id}
  #{inspect(inoutput)}
"""
  end

  defp parse_blocks!(low, high) do
    hash = :rpc |> Gold.getblockhash!(high)
    block = :rpc |> Gold.getblock!(hash)
    GenServer.cast(__MODULE__, {:parse_blocks, block, low, high})
  end

  defp parse_blocks!(block, low, high) do
    block |> process_block

    prev_block = :rpc |> Gold.getblock!(block.previousblockhash)

    cond do
      # Done when low is reached
      prev_block.height == low -> GenServer.cast(__MODULE__, {:parsing_done, low, high})
      # Put every 100th block on message queue as backpressure
      prev_block.height |> is_multiple_of?(100) -> GenServer.cast(__MODULE__, {:parse_blocks, prev_block, low, high})
      # Process next block directly
      true -> prev_block |> parse_blocks!(low, high)
    end
  end

  defp process_block(block) do
    @tasksup_name
    |> Task.Supervisor.async(fn () ->
      txns = block.txns
      |> Enum.map(fn(txn_id) ->
        txn = txn_id |> RPC.gettransaction!

        outputs = txn.outputs
        |> Enum.map(&(parse_script(&1)))

        inputs = txn.inputs
        |> Enum.map(&(parse_script(&1)))

        %{id: txn_id, outputs: outputs, inputs: inputs}
      end)

      # Update the database
      txns
      |> Enum.each(fn(txn) ->
        txn.outputs
        |> Enum.each(&(add_to_db(&1, txn.id)))
        txn.inputs
        |> Enum.each(&(add_to_db(&1, txn.id)))
      end)

      %{height: block.height}
    end)
  end

  defp parse_script(inoutput) do
    parsed = inoutput |> Script.parse_address
    case parsed do
      {:ok, addr} -> {:pkh, Address.raw(addr)}
      other -> other
    end
  end

  defp is_multiple_of?(to_test, base) do
    div = to_test/base
    (Float.ceil(div) == div)
  end

end
