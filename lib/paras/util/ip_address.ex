defmodule Paras.Util.IpAddress do
  @moduledoc """
  Utility functions for dealing with IP Addresess
  """

  @doc """
  Fetches the outbound ip address of caller and returns it as a charlist
  """
  def get_external_ip do
    :inets.start
    {:ok, {_status, _conn_headers, external_address}} = :httpc.request('http://api.ipify.org')
    :inets.stop
    external_address
  end

  @doc """
  Returns the ip address fetched via inet:getif/0
  """
  def get_ip do
    {:ok, addr_list} = :inet.getif
    addr_list
    |> hd
    |> elem(0)
    |> :inet.ntoa
  end
end
