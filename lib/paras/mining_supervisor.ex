defmodule Paras.MiningSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      {Paras.MiningServer, %{}},
      {Paras.MinerPool, %{}},
      {Paras.Miner, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
