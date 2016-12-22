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
      # Init the asset storage agent (TODO: persistent storage)
      :ets.new(:pkh_index, [:set, :public, :named_table])
      store(block_cnt - 3000, :low_cnt)
      store(block_cnt - 3000, :high_cnt)
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
          high_cnt = retrieve(:high_cnt)
          cond do
            high_cnt == block_cnt -> IO.puts "Explorer up to date"
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
    if height |> is_multiple_of?(100) do
      IO.puts ""
      IO.puts height
      elapsed =  DateTime.to_unix(DateTime.utc_now) - state.start_time
      IO.inspect elapsed
    end
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    # ignore
    {:noreply, state}
  end

  def handle_cast({:parse_blocks, block, low, high}, state) do
    block |> parse_blocks!(low, high)
    {:noreply, state |> Map.put(:parsing, true)}
  end

  def handle_cast({:parsing_done, _low, high}, state) do
    # TODO: logging
    high |> store(:high_cnt)
    {:noreply, state |> Map.put(:parsing, false)}
  end

  ## Private

  defp retrieve(key) do
    case :ets.lookup(:pkh_index, key) do
      [{_key, result}] -> result
      [] -> []
    end
  end

  defp store(value, key) do
    :pkh_index
    |> :ets.insert({key, value})
  end

  defp add_to_pkh({:ok, pkh}, txn_id) do
    [txn_id | retrieve(pkh)]
    |> store(pkh)
  end
  defp add_to_pkh({:error, _}, _txn_id), do: nil

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
        |> Enum.map(&(parse_pkh(&1)))

        inputs = txn.inputs
        |> Enum.map(&(parse_pkh(&1)))

        %{id: txn_id, outputs: outputs, inputs: inputs}
      end)

      # Update the pkh_index
      txns
      |> Enum.each(fn(txn) ->
        txn.outputs
        |> Enum.each(&(add_to_pkh(&1, txn.id)))
        txn.inputs
        |> Enum.each(&(add_to_pkh(&1, txn.id)))
      end)

      %{height: block.height}
    end)
  end

  defp parse_pkh(inoutput) do
    parsed = inoutput |> Script.parse_address
    case parsed do
      {:ok, addr} -> {:ok, Address.raw(addr)}
      {:error, :empty} -> {:error, :empty}
      {:error, :op_return} -> {:error, :op_return}
      {:error, :coinbase} -> {:error, :coinbase}
      other ->
        Logger.error "Explorer: Failed to parse PKH from script:"
        IO.inspect inoutput
        other
    end
  end

  defp is_multiple_of?(to_test, base) do
    div = to_test/base
    (Float.ceil(div) == div)
  end

end
