defmodule Mercator.PeerAssets.Repo do
  use GenServer

  @prod_tag { "PAprod", Application.get_env(:peerassets, :PAprod) }
  @test_tag { "PAtest", Application.get_env(:peerassets, :PAtest) }

  ## Client API

  @doc """
  Starts the PeerAssets repository.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: :pa_repo)
  end

  ## Server Callbacks

  def init(:ok) do
    if(!tag_loaded?(@prod_tag), do: load_tag!(@prod_tag))
    if(!tag_loaded?(@test_tag), do: load_tag!(@test_tag))
    {:ok, %{}}
  end

  def handle_call({:lookup, name}, _from, names) do
    {:reply, Map.fetch(names, name), names}
  end

  def handle_cast({:create, name}, names) do
    if Map.has_key?(names, name) do
      {:noreply, names}
    else
#      {:ok, bucket} = KV.Bucket.start_link
      {:noreply} #, Map.put(names, name, bucket)}
    end
  end

  defp tag_loaded?({label, tag}) do
    case :rpc
      |> Gold.getaddressesbyaccount!(label)
      |> Enum.find(fn a -> a == tag.addr end) do
        nil -> false
          _ -> true
    end
  end

  defp load_tag!({label, tag}) do
    :rpc |> Gold.importprivkey(tag.wif, label)
    true = tag_loaded?({label, tag})
  end
end
