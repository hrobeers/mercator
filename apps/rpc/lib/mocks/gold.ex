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
