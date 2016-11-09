defmodule Mocks.Gold do
  use GenServer

  require Gold

  ##
  # Client-side
  ##
  @doc """
  Starts GenServer link with Gold server.
  """
  def start_link(_config), do: GenServer.start_link(__MODULE__, :ok)
  def start_link(_config, name), do: GenServer.start_link(__MODULE__, :ok, name: name)

  ##
  # Server-side
  ##
  def init(:ok) do
    state = Map.new()
    |> Map.put("PAprod", ["miYNy9BbMkQ8Y5VaRDor4mgH5b3FEzVySr"])
    |> Map.put("PAtest", ["mwqncWSnzUzouPZcLQWcLTPuSVq3rSiAAa"])
    {:ok, state}
  end
  def handle_call(request, _from, state)
      when is_atom(request), do: handle_rpc_request(request, [], state)
  def handle_call({request, params}, _from, state)
      when is_atom(request) and is_list(params), do: handle_rpc_request(request, params, state)

  ##
  # Internal functions
  ##
  defp handle_rpc_request(method, params, state) when is_atom(method) do
    case method do
      :getbalance -> {:reply, {:ok, 10.0}, state}

      :getaddressesbyaccount ->
        case params do
          [label] -> {:reply, {:ok, state |> Map.get(label, [])}, state}
                _ -> {:error, {:error}, state}
        end

      :getrawtransaction ->
        case params do
          ["9d4263fdc91aa2bbcdc4f24e4d8296c0045f23362d3cfa5821118d5f1501fafc"] ->
            {:reply, {:ok, "01000000499b195801c19e48d5d660a5156827dff351cbe650ad2882375a259d31112d2ee2e968b68301000000494830450221009544cabe8073f4b5b270484f7570df8a3228efe248cc02beab4ada27fccffda60220193769da9195475f90ea86270183d7322bcae6ae34eb7362b5d61fe3a778aa5601ffffffff02c0b2be96000000001976a914f832cbe3bf67c61404bed3e53a2c219b1d829d6e88ac00e1f505000000001976a91471cf65d5243164de5e2eb4b9403491516430a51e88ac00000000"}, state}
          _ -> {:error, {:error}, state}
        end

      :importprivkey ->
        case params do
          [wif, label] ->
            state |> Map.put(label, wif) # TODO: wif to address
            {:reply, { :ok }, state}
          _ -> {:error, {:error}, state}
        end

      _ -> {:error, to_string(method) <> " not mocked"}
    end
  end

end
