require Base62

defmodule Miner do
  @prefix "vyenaman;"
  @block_size :math.pow(2, 10) |> round
  @pool_size 1024

  def listen do
    receive do
      {:ok, master, target, first, last} ->
        send master, {:ok, mine(target, first, last)}
      {:ok, coins} ->
        coins
        |> Enum.each(&IO.puts("#{@prefix <> &1} #{hashstring(@prefix <> &1)}"))
    end
    listen()
  end

  def mine(target, first, last) do
      first..last
      |> Stream.map(&Base62.encode_int(&1))
      |> Stream.filter(&is_coin?(&1, target))
  end

  def hashstring(string) do
    :crypto.hash(:sha256, string)
    |> Base.encode16
  end

  def is_coin?(string, target) do
    @prefix <> string
    |> hashstring
    |> String.starts_with?(String.duplicate("0", target))
  end

  def init(pool_size \\ @pool_size) do
    1..pool_size |> Enum.map(fn x -> spawn(Miner, :listen, []) end)
  end

  def start(workers, target, first) do
    num_workers = length(workers)
    workers
    |> Stream.with_index
    |> Enum.each(fn ({worker, idx}) ->
        send worker, {:ok, worker, target, first + idx * @block_size, first + (idx + 1) * @block_size - 1}
      end
    )

    start(workers, target, first + num_workers * @block_size)
  end
end
