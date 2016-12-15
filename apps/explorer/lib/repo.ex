defmodule Mercator.Explorer.Repo do
  use GenServer
  require Logger

  alias Bitcoin.Protocol.Types.Script
  alias BitcoinTool.Address
  alias Mercator.RPC

  defp reload_interval, do: 20*1000 # TODO from config

  @agent_name String.to_atom(Atom.to_string(__MODULE__) <> ".Agent")
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
      Agent.start_link(fn ->
        %{
          low_cnt: block_cnt - 100,
          high_cnt: block_cnt - 100
         }
      end, name: @agent_name)
      # Init the task supervisor
      Task.Supervisor.start_link(name: @tasksup_name)
      # Initial blockchain parse (TODO: persistent storage)
      parse_new_blocks(1)
      {:ok, %{connected: true}}
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
          unless high_cnt == block_cnt do
            # Parse
            parse_blocks!(high_cnt, block_cnt)

            # Store
            block_cnt |> store(:high_cnt)
          else
            IO.puts "Explorer up to date"
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

  def handle_info(task_result, state) do
    task_result
    |> IO.inspect
    {:noreply, state}
  end

  ## Private

  defp retrieve(key) do
    Agent.get(@agent_name, &Map.get(&1, key))
  end

  defp store(value, key) do
    Agent.update(@agent_name, &Map.put(&1, key, value))
  end

  defp parse_blocks!(low, high) do
    hash = :rpc |> Gold.getblockhash!(high)
    block = :rpc |> Gold.getblock!(hash)
    [block] |> parse_blocks!(low, high)
  end

  defp parse_blocks!(blocks, low, high) do
    [prev_block | _] = blocks
    block = :rpc |> Gold.getblock!(prev_block.previousblockhash)

    cnt = blocks |> Enum.count
    div = cnt/100
    if (Float.ceil(div) == div) do
      IO.puts cnt
    end

    block |> process_block

    unless (block.height == low) do
      [block | blocks] |> parse_blocks!(low, high)
    else
      [block | blocks]
    end
  end

  defp process_block(block) do
    task = @tasksup_name
    |> Task.Supervisor.async(fn () ->
      outputs = block.txns
      |> Enum.map(&(&1 |> RPC.gettransaction!))
      |> Enum.map(&(&1.outputs))
      |> List.flatten
      |> Enum.filter_map(
        fn(o) -> o.value > 0 end,
        fn(o) ->
          parsed = o |> Script.parse_address
          case parsed do
            {:ok, addr} -> %{address: Address.base58check(addr), value: o.value}
            other -> other
          end
        end)
      %{height: block.height, outputs: outputs}
    end)
  end

end
