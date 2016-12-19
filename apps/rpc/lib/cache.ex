defmodule Mercator.RPC.Cache do
  use GenServer

  ## Client API

  @doc """
  Starts the RPC Cache.
  """
  def start_link(size) do
    GenServer.start_link(__MODULE__, {:ok, %{size: size}}, name: __MODULE__)
  end

  def call(id, fun) do
    GenServer.call(__MODULE__, {:register, id})
    fun.(id)
  end

  ## Server Callbacks

  def init({:ok, %{size: size}}) do
    IO.inspect size
    {:ok, %{size: size, duplicates: 0, total: 0, ids: MapSet.new}}
  end

  def handle_call({:register, id}, _from, state) do
    duplicate = state.ids |> MapSet.member?(id)
    new_state = %{
      size: state.size,
      duplicates: state.duplicates + (if (duplicate) do 1 else 0 end),
      total: state.total + 1,
      ids: state.ids |> MapSet.put(id)
    }
    {:reply, :ok, new_state}
  end
end
