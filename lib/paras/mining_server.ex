defmodule Paras.MiningServer do
  @moduledoc """
  Root server that all miners in the network have to register with in order to be
   provided with a mining challenge
  """
  alias Paras.{MinerPool, Miner}

  use GenServer

  @doc """
  Starts the server in the default state
  """
  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: {:global, :mining_server})
  end

  @doc """
  Registers the PID `registry_pid` from the distributed node `node_name` with the server
  """
  def register(node_name, registry_pid) do
    GenServer.cast({:global, :mining_server}, {:register, node_name, registry_pid})
  end

  @doc """
  Fetches the workers from each pool of nodes that respond to pings
  """
  def get_workers do
    GenServer.call({:global, :mining_server}, {:get_workers})
  end

  @doc """
  Fetches the count of total number of leaf workers (`Miner` instances) attached to the server
  """
  def get_num_workers do
    GenServer.call({:global, :mining_server}, {:get_num_workers})
  end

  @doc """
  Send an async mining message to each worker associated with this server
  `printer_pid` provides the location of a callback process
  that listens to messages with coins mined
  """
  def mine(printer_pid, target, first) do
    GenServer.cast({:global, :mining_server}, {:mine, printer_pid, target, first})
  end

  @doc """
  Initial state of the server
  """
  def init(%{}) do
    {:ok, %{}}
  end

  def handle_call({:get_workers}, _from, nodes) do
    nodes = :maps.filter(fn nd, _ -> Node.ping(nd) == :pong end, nodes)
    active_workers = nodes
    |> Stream.map(fn {_nd, pid} -> MinerPool.get_process_pool(pid) end)
    |> Enum.to_list
    |> List.flatten
    {:reply, active_workers, nodes}
  end

  def handle_call({:get_num_workers}, _from, nodes) do
    nodes = :maps.filter(fn nd, _ -> Node.ping(nd) == :pong end, nodes)
    num_miners = Map.values(nodes)
    |> Stream.map(fn w -> MinerPool.get_pool_size(w) end)
    |> Enum.reduce(0, fn (x, acc) -> acc + x end)
    {:reply, num_miners, nodes}
  end

  def handle_cast({:register, node_name, registry_pid}, nodes) do
    nodes = Map.put(nodes, node_name, registry_pid)
    {:noreply, nodes}
  end

  def handle_cast({:mine, printer_pid, target, first}, nodes) do
    nodes = :maps.filter(fn nd, _ -> Node.ping(nd) == :pong end, nodes)
    Map.values(nodes)
    |> Stream.with_index
    |> Enum.each(fn {pid, offset} ->
        MinerPool.mine(pid, printer_pid, target, first + offset * Miner.block_size() * MinerPool.get_pool_size(pid))
      end)
    {:noreply, nodes}
  end
end
