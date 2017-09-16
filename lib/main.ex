require Logger

defmodule Paras.CLI do
  @moduledoc """
  CLI interface containing entry point `main/1` for running from the CLI
  """
  alias Paras.{Util.IpAddress, Miner, MinerPool, MiningServer}

  @cookie :project1

  @doc """
  Runs the application in either client or server mode
  Client mode is triggered when the passed CLI argument is an IPv4 address
  Server mode is triggered with the passed CLI argument

  ## Parameters
    - args: Args array passed to the CLI upon exection
  """
  def main(args) do
    case args |> parse_args do
      {:ok, num_zeros} when is_integer(num_zeros) ->
        own_name = :erlang.list_to_atom('master@' ++ IpAddress.get_ip())
        pool_pid = setup_node(own_name)
        MiningServer.start_link
        MiningServer.register(node(), pool_pid)
        printer_pid = spawn(__MODULE__, :print_coins, [])
        work(printer_pid, num_zeros, 0)

      {:ok, remote_address} ->
        own_name = :erlang.list_to_atom(elem(:inet.gethostname, 1) ++ '@' ++ IpAddress.get_ip())
        rem_name = :erlang.list_to_atom('master@' ++ :inet.ntoa(remote_address))
        pool_pid = setup_node(own_name)
        Node.connect(rem_name)
        :global.sync
        case :global.whereis_name(:mining_server) |> is_pid do
          false ->
            Logger.error("Exit reason: Unable to connect to remote address")
          true ->
            MiningServer.register(node(), pool_pid)
            wait_for_exit(rem_name)
            IO.puts "Remote server down, goodbye!"
        end

      {:error, reason} ->
        Logger.error("Exit reason: #{reason}")
    end
  end

  @doc """
  Runs a recieve loop to wait for messages containing coins and print them to stdout
  """
  def print_coins do
    receive do
      {:print, coins} ->
        coins
        |> Enum.each(&IO.puts("#{&1}\t#{Miner.hashstring(&1) |> String.downcase}"))
    end
    print_coins()
  end

  @doc """
  Parses parameters input from CLI to return {:ok, parsed_data} or {:error, reason}

  ## Parameters
    - args: Args array passed to the CLI upon exection
  """
  defp parse_args([]), do: {:error, "No arguments found, expected integer or IPv4 address"}
  defp parse_args([_head | tail]) when tail != [], do: {:error, "Too many arguments"}
  defp parse_args([data]) do
    cond do
      Regex.match?(~r/\d.\d.\d.\d/, data) ->
        :inet.parse_address(to_charlist(data))
      Regex.match?(~r/\d/, data) ->
        {value, ""} = Integer.parse(data)
        {:ok, value}
      true ->
        {:error, "Argument type mismatch, expected integer or IPv4 address"}
    end
  end

  @doc """
  Converts the current node into a distributed node and sets a common cookie.
  This function also initializes a pool of workers and registers it with the local MinerPool
  GenServer instance

  ## Parameters
    - own_name: The name by which this node will be referred to on the network
  """
  defp setup_node(own_name) when is_atom(own_name) do
    Node.start(own_name)
    Node.set_cookie(@cookie)

    {:ok, pool} = MinerPool.start_link
    MinerPool.populate(pool)
    pool
  end

  @doc """
  Runs the work loop of the server or waits for a mining server to be registered with :global
  to send it work

  ## Parameters
    - printer_pid: Pid of the process listening for coins genereted by the pool
    - target: Number of leading zeros expected in the sha256 of the coin
    - first: Index from which to start mining
  """
  defp work(printer_pid, target, first) do
    if :global.whereis_name(:mining_server) |> is_pid do
      num_miners = MiningServer.get_num_workers
      MiningServer.mine(printer_pid, target, first)
      work(printer_pid, target, first + num_miners * Miner.block_size() - 1)
    end
  end

  defp wait_for_exit(remote_name) do
    if Node.ping(remote_name) == :pong do
      wait_for_exit(remote_name)
    end
  end
end
