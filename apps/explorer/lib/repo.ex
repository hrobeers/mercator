defmodule Mercator.Explorer.Repo do
  use GenServer
  require Logger

  alias Bitcoin.Protocol.Types.Script
  alias BitcoinTool.Address
  alias Mercator.RPC

  defp reload_interval, do: 60*60*1000 # TODO from config

  ## Client API

  @doc """
  Starts the Explorer repository.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: :explorer_repo)
  end

  ## Server Callbacks

  def init(:ok) do
    # init the asset storage agent
    Agent.start_link(fn ->
      %{
        block_cnt: (:rpc |> Gold.getblockcount!()) - 10
       }
    end, name: __MODULE__)
    # init the Repo
    init(:retry, true)
  end

  defp init(:retry, log) do
    try do
      {:ok, _} = :rpc |> Gold.getblockcount
      Logger.info("Explorer.Repo: RPC connection initialized (reload_interval: " <> Integer.to_string(reload_interval) <> ")")
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
          unless retrieve(:block_cnt) == block_cnt do
            # Parse
            parse_new_blocks!(block_cnt)
            |> Enum.map(&(&1.txns))
            |> List.flatten
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
            |> IO.inspect
            # Store
            block_cnt |> store(:block_cnt)
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

  ## Private

  defp retrieve(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end

  defp store(value, key) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  defp parse_new_blocks!(parse_until) do
    [] |> parse_new_blocks!(retrieve(:block_cnt), parse_until)
  end

  defp parse_new_blocks!(blocks, parsed_cnt, parse_until) do
    hash = :rpc |> Gold.getblockhash!(parsed_cnt)
    block = :rpc |> Gold.getblock!(hash)

    div = parsed_cnt/100
    if (Float.ceil(div) == div) do
      IO.puts parsed_cnt
    end

    if (parsed_cnt < parse_until) do
      [block | blocks] |> parse_new_blocks!(parsed_cnt+1, parse_until)
    else
      [block | blocks]
    end
  end

end
