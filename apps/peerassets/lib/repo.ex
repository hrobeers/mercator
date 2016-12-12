defmodule Mercator.PeerAssets.Repo do
  use GenServer
  require Logger

  @agent_name String.to_atom(Atom.to_string(__MODULE__) <> ".Agent")

  alias Mercator.PeerAssets.Types.DeckSpawn

  defp reload_interval, do: Application.get_env(:peerassets, :reload_interval)
  defp prod_tag, do: Application.get_env(:peerassets, :PAprod)
  defp test_tag, do: Application.get_env(:peerassets, :PAtest)

  @tag_fee Gold.btc_to_decimal(0.01)
  @listtxn_size if Mix.env == :test, do: 2, else: 10

  ## Client API

  @doc """
  Starts the PeerAssets repository.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Returns a list of registered assets.
  """
  def list_assets(net \\ :PAprod) do
    Agent.get(@agent_name, &Map.fetch(&1, net))
  end

  @doc """
  Imports the specified P2TH private key.
  """
  def load_tag!(tag) do
    if (!tag_loaded?(tag)) do
      :rpc |> Gold.importprivkey(tag.wif, tag.label)
      true = tag_loaded?(tag)
    end
  end

  ## Server Callbacks

  def init(:ok) do
    # init the asset storage agent
    Agent.start_link(fn ->
      %{
        block_cnt: 0,
        PAprod: [],
        PAtest: []
       }
    end, name: @agent_name)
    # init the Repo
    init(:retry, true)
  end

  defp init(:retry, log) do
    try do
      load_tag!(prod_tag)
      load_tag!(test_tag)
      Logger.info("PeerAssets.Repo: initialized (reload_interval: " <> Integer.to_string(reload_interval) <> ")")
      reload_assets(1)
      {:ok, %{connected: true}}
    rescue
      _ ->
        if log, do: Logger.warn("PeerAssets.Repo: Failed to establish rpc connection. Will retry every second.")
        # Block synchronously until connection is established
        :timer.sleep(1000)
        init(:retry, false)
    end
  end

  defp reload_assets(timeout) do
    Process.send_after(self(), :reload, timeout)
  end
  def handle_info(:reload, state) do
    new_state =
      case :rpc |> Gold.getblockcount do
        {:ok, block_cnt} ->
          # Log reconnection if wasn't connected
          unless Map.get(state, :connected), do: Logger.info("PeerAssets.Repo: rpc connection re-established")
          state = state |> Map.put(:connected, true)

          # Reload assets if new block arrived
          unless retrieve(:block_cnt) == block_cnt do
              # Parse
              prod_assets = load_assets!(prod_tag)
              test_assets = load_assets!(test_tag)
              # Store
              block_cnt |> store(:block_cnt)
              prod_assets |> store(:PAprod)
              test_assets |> store(:PAtest)
          end

          # Return state
          state
        {:error, _} ->
          # TODO: log error
          if Map.get(state, :connected), do: Logger.warn("PeerAssets.Repo: rpc connection lost")
          state |> Map.put(:connected, false)# no connection, just ignore until restored
      end

    reload_assets(reload_interval)
    {:noreply, new_state}
  end

  ## Private

  defp retrieve(key) do
    Agent.get(@agent_name, &Map.get(&1, key))
  end

  defp store(value, key) do
    Agent.update(@agent_name, &Map.put(&1, key, value))
  end

  defp tag_loaded?(tag) do
    case :rpc
      |> Gold.getaddressesbyaccount!(tag.label)
      |> Enum.find(fn a -> a == tag.address end) do
        nil -> false
          _ -> true
    end
  end

  defp load_assets!(tag) do
    [] |> load_assets!(0, tag)
  end

  defp load_assets!(assets, full_cnt, tag) do
    new_assets = :rpc
    |> Gold.listtransactions!(tag.label, @listtxn_size, full_cnt)

    [new_assets | assets]
    |> load_more_assets!(full_cnt+@listtxn_size, tag)
  end

  defp load_more_assets!([[] | assets], _full_cnt, tag) do
    parsed = assets
    |> List.flatten
    |> Enum.reverse
    |> Enum.filter_map(&(sufficient_tag_fee(&1)),
      fn(%Gold.Transaction{txid: txid}) ->
        txid
        |> Mercator.RPC.gettransaction!
        |> DeckSpawn.parse_txn
      end)

    # Filter for successfully parsed
    success = for {:ok, valid} <- parsed, do: valid

    # Filter for correctly placed tag (some may refer both PAprod & PAtest)
    # TODO: add such a case to official test vectors
    success
    |> Enum.filter(&(&1.tag_address == tag.address))
  end

  defp load_more_assets!(assets, full_cnt, tag) do
    assets |> load_assets!(full_cnt, tag)
  end

  defp sufficient_tag_fee(%Gold.Transaction{amount: amount}) do
    amount
    |> Decimal.compare(@tag_fee)
    |> Decimal.to_integer != -1
  end

end
