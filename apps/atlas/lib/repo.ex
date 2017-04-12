defmodule Mercator.Atlas.Repo do
  use GenServer
  require Logger

  alias Bitcoin.Protocol.Types.Script
  alias BitcoinTool.Address
  alias Mercator.Atlas.DB
  alias Mercator.RPC

  defp reload_interval, do: Application.get_env(:atlas, :reload_interval)
  defp start_height(block_cnt) do
    cnfg = Application.get_env(:atlas, :start_height)
    if (cnfg < 0) do
      block_cnt + cnfg
    else
      cnfg
    end
  end

  @tasksup_name String.to_atom(Atom.to_string(__MODULE__) <> ".TaskSup")
  @batch_rpc Application.get_env(:atlas, :batch_rpc) # Read at compile time
  @conf_cnt 10

  ## Client API

  @doc """
  Starts the Atlas repository.
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
      Logger.info("Atlas.Repo: RPC connection initialized (reload_interval: " <> Integer.to_string(reload_interval) <> ")")
      # Init the ETS tables
      :ok = DB.init()
      # Set initial parsing state
      DB.store(start_height(block_cnt), :low_cnt, :pkh_index)
      DB.store(start_height(block_cnt), :high_cnt, :pkh_index)
      # Init the task supervisor
      Task.Supervisor.start_link(name: @tasksup_name)
      # Initial blockchain parse (TODO: persistent storage)
      parse_new_blocks(1)
      {:ok, %{connected: true, parsing: false, start_time: DateTime.to_unix(DateTime.utc_now)}}
    rescue
      _ ->
        if log, do: Logger.warn("Atlas.Repo: Failed to establish rpc connection. Will retry every second.")
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
          unless Map.get(state, :connected), do: Logger.info("Atlas.Repo: rpc connection re-established")
          state = state |> Map.put(:connected, true)

          # Parse new blocks when they arrived
          high_cnt = DB.retrieve(:high_cnt, :pkh_index)
          cond do
            high_cnt == block_cnt ->
              Logger.info("Atlas.Repo: up to date")
            state.parsing == false ->
              update_unconfirmed()
              parse_blocks!(high_cnt, block_cnt)
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
      Logger.info("Atlas.Repo: Parsing blocks in range: " <> range <> " progress: " <> progress)
    end
    block |> parse_blocks!(low, high)
    {:noreply, state |> Map.put(:parsing, true)}
  end

  def handle_cast({:parsing_done, low, high}, state) do
    if (high-low > 1000) do
      range = Integer.to_string(low) <> " - " <> Integer.to_string(high)
      Logger.info("Atlas.Repo: Parsing blocks in range: " <> range <> " progress: 100%")
    end

    high |> DB.store(:high_cnt, :pkh_index)
    {:noreply, state |> Map.put(:parsing, false)}
  end

  ## Private

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
    # Convert block hash to binary
    block = block
    |> Map.put(:hash, block.hash |> Base.decode16!(case: :lower))

    block.txns
    |> Enum.map(&(&1 |> Base.decode16!(case: :lower)))
    |> DB.store(block.height, :blocks)
    if block.confirmations < @conf_cnt do
      block
      |> DB.store(block.hash, :unconfirmed)
    end

    @tasksup_name
    |> Task.Supervisor.async(fn () ->
      txns = case @batch_rpc do
               false ->
                 block.txns
                 |> Enum.with_index
                 |> Enum.map(fn({txn_id, idx}) ->
                   txn = txn_id
                   |> RPC.gettransaction!

                   outputs = txn.outputs
                   |> Enum.map(&(parse_script(&1)))

                   inputs = txn.inputs
                   |> Enum.map(&(parse_script(&1)))

                   %{idx: idx, txn_id: txn_id, outputs: outputs, inputs: inputs}
                 end)
               true ->
                 idx_map = block.txns
                 |> Enum.with_index
                 |> Enum.into(%{})
                 block.txns
                 |> RPC.gettransactions!
                 |> Enum.map(fn {txn_id, txn} ->
                   outputs = txn.outputs
                   |> Enum.map(&(parse_script(&1)))

                   inputs = txn.inputs
                   |> Enum.map(&(parse_script(&1)))

                   %{idx: idx_map |> Map.get(txn_id), txn_id: txn_id, outputs: outputs, inputs: inputs}
                 end)
             end

      # Update the database
      txns
      |> Enum.each(fn(txn) ->
        txn.outputs
        |> Enum.with_index
        |> Enum.each(&(DB.add_output(&1, txn, block)))
        txn.inputs
        |> Enum.with_index
        |> Enum.each(&(DB.add_input(&1, txn, block)))
      end)

      %{height: block.height}
    end)
  end

  defp parse_script(inoutput) do
    parsed = inoutput |> Script.parse
    case parsed do
      {:address, addr} -> {:pkh, Address.raw(addr)}
      other -> other
    end
  end

  defp update_unconfirmed() do
    Logger.info("Atlas.Repo: updating unconfirmed table")
    update_unconfirmed(:ets.first(:unconfirmed),[])
  end
  defp update_unconfirmed(:"$end_of_table", to_delete) do
    # TODO: investigate what happens to orphan blocks
    to_delete
    |> Enum.each(&(&1 |> DB.delete(:unconfirmed)))
    :ok
  end
  defp update_unconfirmed(hash, to_delete) do
    block = :rpc |> Gold.getblock!(hash |> Base.encode16(case: :lower))
    block |> DB.store(hash, :unconfirmed)
    if block.confirmations >= @conf_cnt do
      update_unconfirmed(:ets.next(:unconfirmed, hash), [hash | to_delete])
    else
      update_unconfirmed(:ets.next(:unconfirmed, hash), to_delete)
    end
  end

  defp is_multiple_of?(to_test, base) do
    div = to_test/base
    (Float.ceil(div) == div)
  end

end
