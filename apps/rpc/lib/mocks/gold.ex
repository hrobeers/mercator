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

      :getblockcount -> {:reply, {:ok, 12345}, state}

      :getaddressesbyaccount ->
        case params do
          [label] -> {:reply, {:ok, state |> Map.get(label, [])}, state}
                _ -> {:error, {:error}, state}
        end

      :getrawtransaction ->
        case params do
          ["9d4263fdc91aa2bbcdc4f24e4d8296c0045f23362d3cfa5821118d5f1501fafc"] ->
            {:reply, {:ok, "01000000499b195801c19e48d5d660a5156827dff351cbe650ad2882375a259d31112d2ee2e968b68301000000494830450221009544cabe8073f4b5b270484f7570df8a3228efe248cc02beab4ada27fccffda60220193769da9195475f90ea86270183d7322bcae6ae34eb7362b5d61fe3a778aa5601ffffffff02c0b2be96000000001976a914f832cbe3bf67c61404bed3e53a2c219b1d829d6e88ac00e1f505000000001976a91471cf65d5243164de5e2eb4b9403491516430a51e88ac00000000"}, state}

          ["356b9736ee7dbf387ea7b10a16beda8ea1ad5db0cbc53e749f5e4b3cf7545552"] ->
            {:reply, {:ok, "01000000f208095801f727bca1f9359f2c067b1d5d41b5a8d9836b9e19b36745b5463e4e79f6f0fa30020000006b48304502202013847fdd489077bd5b420f00e0c9c5af95bb0807b5309962e7cdea440ee4f9022100b070b2882cd2132f6e48c61f7a0219f09869472c022e1c65df4a21d76c7731190121036a34c6e2c719b81717b0a5ed5260de446932b253bf84637cb8016286e03f50d2ffffffff0310270000000000001976a914b311d5766f9623408747554bcdec1d8dc05eeaf088ac00000000000000002e6a2c0801122468726f6265657273206f77657320796f75203130305050432c207265616c206f6e6573211802200a10d64b00000000001976a9146759a0764127ae9047bff989f330bc2c5d0cfa1e88ac00000000"}, state}

          ["8903462de0633b528ea6fd269c9bed19a415c64e9c0f9e1974c88c4667eecd42"] ->
            {:reply, {:ok, "01000000af5e1258010000000000000000000000000000000000000000000000000000000000000000ffffffff11000000000300000000000000d70000be0a0000000001e0da4f6c010000002321036a34c6e2c719b81717b0a5ed5260de446932b253bf84637cb8016286e03f50d2ac00000000"}, state}

          _ -> {:error, {:error}, state}
        end

      :importprivkey ->
        case params do
          [wif, label] ->
            state |> Map.put(label, wif) # TODO: wif to address
            {:reply, { :ok }, state}
          _ -> {:error, {:error}, state}
        end

      :listtransactions ->
        case params do
          ["PAtest", _cnt, 0] ->
            {:reply, {:ok, [%{"account" => "PAtest", "address" => "mwqncWSnzUzouPZcLQWcLTPuSVq3rSiAAa",
                              "amount" => 0.01,
                              "blockhash" => "0000000037fc24cc5f769a74aa5ce4c7501ede10369b94ba3f2fdc79d28ffe85",
                              "blockindex" => 1, "category" => "receive", "confirmations" => 4595,
                              "time" => 1476987122,
                              "txid" => "356b9736ee7dbf387ea7b10a16beda8ea1ad5db0cbc53e749f5e4b3cf7545552"}]},
            state}
          _ -> {:reply, {:ok, []}, state}
        end

      _ -> {:error, to_string(method) <> " not mocked"}
    end
  end

end
