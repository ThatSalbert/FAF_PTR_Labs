defmodule GenericSupervisor do
  use Supervisor

  def start_link(id, type, min_time, max_time, num_workers, name) do
    Supervisor.start_link(__MODULE__, {id, type, min_time, max_time, num_workers, name}, name: name)
  end

  def init({id, type, min_time, max_time, num_workers, _name}) do
    children =
      for i <- 1..num_workers,
        do: %{
            id: :"#{id}#{i}",
            start: {type, :start_link, [:"#{id}#{i}", min_time, max_time]}
          }

    Supervisor.init(children, strategy: :one_for_one)
  end

  def getNumWorkers() do
    Supervisor.count_children(GenericSupervisor) |> Map.get(:specs)
  end

  def whichWorkers() do
    Supervisor.which_children(GenericSupervisor)
  end

  def addWorker(id_module, type) do
    id = getNumWorkers() + 1
    Supervisor.start_child(GenericSupervisor, %{
      id: :"#{id_module}#{id}",
      start: {type, :start_link, [:"#{id_module}#{id}", 10, 50]}
    })
    IO.inspect("Added worker #{id_module}#{id}")
  end

  def removeWorker() do
    workers = whichWorkers() |> Enum.map(fn {id, _, _, _} -> id end)
    Supervisor.terminate_child(GenericSupervisor, List.first(workers))
    Supervisor.delete_child(GenericSupervisor, List.first(workers))
    IO.inspect("Removed worker #{List.first(workers)}")
  end
end
