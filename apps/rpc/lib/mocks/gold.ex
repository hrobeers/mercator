defmodule Mocks.Gold do
  use GenServer

  require Gold

  ##
  # Client-side
  ##
  @doc """
  Starts GenServer link with Gold server.
  """
  def start_link(config), do: GenServer.start_link(__MODULE__, config)
  def start_link(config, name), do: GenServer.start_link(__MODULE__, config, name: name)

  ##
  # Server-side
  ##
  def handle_call(request, _from, config)
      when is_atom(request), do: handle_rpc_request(request, [], config)
  def handle_call({request, params}, _from, config)
      when is_atom(request) and is_list(params), do: handle_rpc_request(request, params, config)

  ##
  # Internal functions
  ##
  defp handle_rpc_request(method, params, config) when is_atom(method) do
    case method do
      :getbalance -> {:reply, {:ok, 10.0}, config}

      :getaddressesbyaccount ->
          case params do
            ["PAprod"] -> {:reply, {:ok, ["miYNy9BbMkQ8Y5VaRDor4mgH5b3FEzVySr"]}, config}
            ["PAtest"] -> {:reply, {:ok, ["mwqncWSnzUzouPZcLQWcLTPuSVq3rSiAAa"]}, config}
          end

      _ -> {:error, to_string(method) <> " not mocked"}
    end
  end

end
