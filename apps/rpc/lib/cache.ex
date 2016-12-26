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
    case :ets.lookup(:txn_cache, id) do
      [{id, result}] -> result
      [] ->
        result = fun.(id)
        GenServer.call(__MODULE__, {:register, id, result})
        result
    end
  end

  ## Server Callbacks

  def init({:ok, %{size: size}}) do
    :ets.new(:txn_cache, [:set, :protected, :named_table, read_concurrency: true])
    {:ok, %{size: size,
            total: 0,
            queue: :queue.new}}
  end

  def handle_call({:register, id, result}, _from, state) do
    full = state.total == state.size
    :ets.insert(:txn_cache, {id, result})

    new_queue = case full do
                  false -> state.queue
                  true ->
                    {{:value, to_remove}, q} = :queue.out(state.queue)
                    :ets.delete(:txn_cache, to_remove)
                    q
                end

    new_state = %{
      size: state.size,
      total: state.total + (if (full) do 0 else 1 end),
      queue: :queue.in(id, new_queue)
    }

    {:reply, :ok, new_state}
  end
end
