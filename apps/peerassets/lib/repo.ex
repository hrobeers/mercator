defmodule Mercator.PeerAssets.Repo do
  use GenServer

  alias Mercator.PeerAssets.Types.DeckSpawn

  @reload_interval Application.get_env(:peerassets, :reload_interval)
  @prod_tag Application.get_env(:peerassets, :PAprod)
  @test_tag Application.get_env(:peerassets, :PAtest)

  @tag_fee Gold.btc_to_decimal(0.01)
  @listtxn_size if Mix.env == :test, do: 2, else: 10

  ## Client API

  @doc """
  Starts the PeerAssets repository.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: :pa_repo)
  end

  @doc """
  Returns a list of registered assets.
  """
  def list_assets(net \\ :PAprod) do
    GenServer.call(:pa_repo, {:list_assets, net})
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
    load_tag!(@prod_tag)
    load_tag!(@test_tag)
    reload_assets(1)
    {:ok, %{block_cnt: 0}}
  end

  def handle_call({:list_assets, net}, _from, state) do
    {:reply, Map.fetch(state, net), state}
  end

  defp reload_assets(timeout) do
    Process.send_after(self(), :reload, timeout)
  end
  def handle_info(:reload, state) do
    block_cnt = :rpc |> Gold.getblockcount!

    state = cond do
      Map.get(state, :block_cnt) == block_cnt ->
        state # no changes
      true ->
        %{block_cnt: block_cnt,
          PAprod: load_assets!(@prod_tag),
          PAtest: load_assets!(@test_tag)}
    end

    reload_assets(@reload_interval)
    {:noreply, state}
  end

  ## Private

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
    |> Enum.reverse
    |> List.flatten
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
