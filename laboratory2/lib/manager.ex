defmodule Manager do
  use GenServer

  def start_link(time_check, max_workers, min_workers) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {time_check, max_workers, min_workers})
    Process.send_after(pid, :manage, time_check)
    {:ok, pid}
  end

  def init({time_check, max_worker, min_worker}) do
    {:ok, {time_check, max_worker, min_worker}}
  end

  def calcLoad() do
    currentWorkers = WorkerPool.whichWorkers() |> Enum.map(fn {_, pid, _, _} -> pid end)
    numWorkers = Enum.count(currentWorkers)
    currentLoad = Enum.reduce(currentWorkers, 0, fn pid, acc ->
      {_, queue} = Process.info(pid, :message_queue_len)
      acc + queue
    end)
    {numWorkers, currentLoad}
  end

  def handle_info(:manage, {time_check, max_worker, min_worker}) do
    {numWorkers, currentLoad} = calcLoad()
    laFormula = (currentLoad / numWorkers) / 100
    IO.inspect("Current load: #{laFormula}")
    cond do
      laFormula > 0.8 and numWorkers < max_worker ->
        WorkerPool.addWorker()
      laFormula < 0.2 and numWorkers > min_worker ->
        WorkerPool.removeWorker()
      true ->
        :no_change
    end
    Process.send_after(self(), :manage, time_check)
    {:noreply, {time_check, max_worker, min_worker}}
  end
end
