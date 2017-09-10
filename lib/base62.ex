defmodule Base62 do
  @moduledoc """
  Namspace of utililty functions to deal with conversion to and from base62 to base 10
  """
  @valid_alphabet "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.split("")

  @spec encode_int(Integer.t) :: String.t
  def encode_int(val) do
    val
    |> Integer.digits(62)
    |> Enum.map(&Enum.at(@valid_alphabet, &1))
    |> to_string
  end
end
