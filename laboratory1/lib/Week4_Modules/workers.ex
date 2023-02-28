defmodule WorkerPool do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def workerEcho(pid, msg) do
    GenServer.call(pid, {:echo, msg})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:echo, msg}, _from, state) do
    {:reply, msg, state}
  end
end

defmodule PoolSupervisor do
  use Supervisor

  def start_link(num) do
    Supervisor.start_link(__MODULE__, num)
  end

  def init(num) do
    children = Enum.map(
      1..num,
      fn i ->
        %{
          id: i,
          start: {WorkerPool, :start_link, []}
        }
      end
    )

    Supervisor.init(children, strategy: :one_for_one)
  end

  def getWorker(pid, id) do
    Supervisor.which_children(pid) |> Enum.find(fn {i, _, _, _} -> i == id end)
  end
end

{:ok, pidsupervisor} = PoolSupervisor.start_link(3)
pidworker = PoolSupervisor.getWorker(pidsupervisor, 1) |> elem(1)
IO.puts(WorkerPool.workerEcho(pidworker, "Hello World"))
pidworker |> Process.exit(:kill)
