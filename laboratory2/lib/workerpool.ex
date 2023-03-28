defmodule WorkerPool do
  use Supervisor

  def start_link(min_time, max_time) do
    Supervisor.start_link(__MODULE__, {min_time, max_time}, name: __MODULE__)
  end

  def init({min_time, max_time}) do
    children = [
      %{
        id: :printer1,
        start: {Printer, :start_link, [:printer1, min_time, max_time]}
      },
      %{
        id: :printer2,
        start: {Printer, :start_link, [:printer2, min_time, max_time]}
      },
      %{
        id: :printer3,
        start: {Printer, :start_link, [:printer3, min_time, max_time]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def getNumWorkers() do
    Supervisor.count_children(WorkerPool) |> Map.get(:specs)
  end

  def whichWorkers() do
    IO.inspect(Supervisor.which_children(WorkerPool))
    Supervisor.which_children(WorkerPool)
  end

  def addWorker() do
    id = getNumWorkers() + 1
    Supervisor.start_child(WorkerPool, %{
      id: "printer#{id}",
      start: {Printer, :start_link, [:"printer#{id}", 10, 50]}
    })
    IO.inspect("Added worker printer#{id}")
  end

  def removeWorker() do
    workers = whichWorkers() |> Enum.map(fn {id, _, _, _} -> id end)
    Supervisor.terminate_child(WorkerPool, List.first(workers))
    Supervisor.delete_child(WorkerPool, List.first(workers))
    IO.inspect("Removed worker #{List.first(workers)}")
  end
end
