defmodule Paras.Miner do
  @moduledoc """
  Service representing a single, stateless miner
  """
  alias Paras.Util.Base62

  use GenServer

  @prefix "vyenaman;"
  @block_size :math.pow(2, 10) |> round

  @doc """
  Starts the server in the default state
  """
  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  @doc """
  Finds the bitcoins in the range `first..(first + @block_ssize)`
  Block size is defined to be 1024 by default and pass them to the process `printer_pid`
  that handles the coins found
  """
  def mine(pid, printer_pid, target, first) do
    GenServer.cast(pid, {:mine, printer_pid, target, first})
  end

  @doc """
  Returns the initial state of Miner for use by `start_link/0`
  """
  def init do
    {:ok, []}
  end

  @doc """
  Return the value of `block_size` attribute used by the Miner
  """
  def block_size, do: @block_size

  @doc """
  Computes the sha256 hash of the given string and returns a base16 binary string
  """
  def hashstring(string) do
    :crypto.hash(:sha256, string)
    |> Base.encode16
  end

  @doc """
  Checks if the input `string` is a valid coin with exactly `target` number of leading zeros
  """
  def is_coin?(string, target) do
    zeros = String.duplicate("0", target)
    one_extra_zero = zeros <> "0"
    hashed_string = (@prefix <> string) |> hashstring
    String.starts_with?(hashed_string, zeros) and (not String.starts_with?(hashed_string, one_extra_zero))
  end

  def handle_cast({:mine, printer_pid, target, first}, state) do
    coins = first..(first + @block_size - 1)
    |> Stream.map(&Base62.encode_int(&1))
    |> Stream.filter(&is_coin?(&1, target))
    |> Enum.map(&(@prefix <> &1))

    send printer_pid, {:print, coins}

    {:noreply, state}
  end
end
