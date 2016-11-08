defmodule Mercator.PeerAssets.Repo do
  use GenServer

  @prod_tag Application.get_env(:peerassets, :PAprod)
  @test_tag Application.get_env(:peerassets, :PAtest)

  ## Client API

  @doc """
  Starts the PeerAssets repository.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: :pa_repo)
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

  defp tag_loaded?(tag) do
    case :rpc
      |> Gold.getaddressesbyaccount!(tag.label)
      |> Enum.find(fn a -> a == tag.address end) do
        nil -> false
          _ -> true
    end
  end

  ## Server Callbacks

  def init(:ok) do
    load_tag!(@prod_tag)
    load_tag!(@test_tag)
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
end
