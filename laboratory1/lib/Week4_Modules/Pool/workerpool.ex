defmodule WorkerPool do
  use Supervisor

  def start_link(num) do
    Supervisor.start_link(__MODULE__, num, name: __MODULE__)
  end

  def init(num) do
    children = [
      worker(WorkerLogic, [])
    ]
    supervise(children, strategy: :one_for_one)
  end

  def workerEcho(message) do
    GenServer.call(__MODULE__, {:workerEcho, message})
  end
end

{:ok, pid} = WorkerPool.start_link(3)
Supervisor.count_children(pid)
