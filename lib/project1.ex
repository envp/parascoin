defmodule Project1 do

  def parse_args([]), do: {:error, "No arguments found, expected integer or IPv4 address"}

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

  def parse_args(_), do: {:error, "Too many arguments"}

  def main(args) do
    case args |> parse_args do
      {:ok, num_zeros} when is_integer(num_zeros) ->
        worker_pool = Miner.init()
        Miner.start(worker_pool, num_zeros, 0)
      # Do nothing for networked stuff for now
      {:ok, inet_addr} ->
        inet_addr
      {:error, reason} ->
        IO.puts "Exit reason: #{reason}"
    end
  end
end
