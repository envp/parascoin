defmodule Paras.MinerPool do
  @moduledoc """
  Bare bones process pool that can async-broadcast work messages to all children in its tree
  """
  @pool_scalar 10

  alias Paras.Miner

  use GenServer

  @doc """
  Starts the pool in the default state
  """
  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  @doc """
  Returns the pids in the worker pool associated with this MinerPool PID
  """
  def get_process_pool(pid) do
    GenServer.call(pid, :get_process_pool)
  end

  @doc """
  Returns the size of pool associated with the current MinerPool PID
  """
  def get_pool_size(pid) do
    GenServer.call(pid, :get_pool_size)
  end

  @doc """
  Returns the default pool size used `pool_scalar * num_logical_processors`
  """
  def default_pool_size, do: @pool_scalar * :erlang.system_info(:logical_processors_available)

  @doc """
  Populate the pool with the default number of workers
  """
  def populate(pid) do
    workers = 1..__MODULE__.default_pool_size()
    |> Enum.map(fn _ -> elem(Miner.start_link, 1) end)

    GenServer.cast(pid, {:add_workers, workers})
  end

  @doc """
  Registers the list of workers provided with the MinerPool PID
  """
  def add_workers(pid, workers) do
    GenServer.cast(pid, {:add_workers, workers})
  end

  @doc """
  Send an async request with a callback PID to all child workers to mine a specific kind of coin
  """
  def mine(pid, printer_pid, target, first) do
    GenServer.cast(pid, {:mine, printer_pid, target, first})
  end

  @doc """
  Initial state for the miner pool (no workers associated)
  """
  def init(%{}) do
    {:ok, %{workers: []}}
  end

  def handle_call(:get_process_pool, _from, pool) do
    {:reply, pool.workers, pool}
  end

  def handle_call(:get_pool_size, _from, pool) do
    {:reply, length(pool.workers), pool}
  end

  def handle_cast({:add_workers, workers}, pool) do
    {:noreply, %{workers: pool.workers ++ workers}}
  end

  def handle_cast({:mine, printer_pid, target, first}, pool) do
    pool.workers
    |> Stream.with_index
    |> Enum.each(fn {pid, offset} -> Miner.mine(pid, printer_pid, target, first + offset * Miner.block_size) end)
    {:noreply, pool}
  end
end
