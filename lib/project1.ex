require Logger

defmodule Paras do
  alias Paras.{Util.IpAddress, Miner, MinerRegistry, MiningServer}

  @cookie :project1

  def parse_args([]), do: {:error, "No arguments found, expected integer or IPv4 address"}
  def parse_args([_head | tail]) when tail != [], do: {:error, "Too many arguments"}
  def parse_args([data]) do
    cond do
      Regex.match?(~r/\d/, data) ->
        {value, ""} = Integer.parse(data)
        {:ok, value}
      Regex.match?(~r/\d.\d.\d.\d/, data) ->
        :inet.parse_address(data)
      true ->
        {:error, "Argument type mismatch, expected integer or IPv4 address"}
    end
  end

  def setup_node(own_name) when is_atom(own_name) do
    Node.start(own_name)
    Node.set_cookie(@cookie)

    workers = 1..Miner.pool_size() |> Enum.map(fn _ -> elem(Miner.start_link, 1) end)
    {:ok, registry} = MinerRegistry.start_link
    MinerRegistry.add_workers(registry, workers)
    registry
  end

  def work(target, first) do
    if Process.whereis(:mining_server) |> is_pid do
      workers = MiningServer.get_workers
      num_workers = length(workers)
      coins = workers
      |> Stream.with_index
      |> Enum.map(fn {pid, offset} -> Miner.mine(pid, target, first + offset * Miner.block_size) end)
      |> List.flatten
      |> Enum.each(&IO.puts("#{&1}\t#{Miner.hashstring(&1)}"))
      work(target, num_workers * Miner.block_size - 1)
    end
  end

  def main(args) do
    case args |> parse_args do
      {:ok, num_zeros} when is_integer(num_zeros) ->
        # Miner.start(Miner.init(), num_zeros, 0)
        own_name = :erlang.list_to_atom('master@' ++ IpAddress.get_external_ip())
        registry_pid = Paras.setup_node(own_name)
        MiningServer.start_link
        MiningServer.register(node(), registry_pid)
        work(num_zeros, 0)

      {:ok, remote_address} when is_tuple(remote_address) ->
        own_name = :erlang.list_to_atom(:inet.gethostname ++ '@' ++ IpAddress.get_external_ip())
        rem_name = :erlang.list_to_atom('master@' ++ remote_address)
        registry_pid = Paras.setup_node(own_name)
        Node.spawn(rem_name, fn -> MiningServer.register(node(), registry_pid) end)

      {:error, reason} ->
        Logger.error("Exit reason: #{reason}")
    end
  end
end
