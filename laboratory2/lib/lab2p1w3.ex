defmodule Lab2P1W3.Manager do
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
    currentWorkers = Lab2P1W2.WorkerPool.whichWorkers() |> Enum.map(fn {_, pid, _, _} -> pid end)
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
        Lab2P1W2.WorkerPool.addWorker()
      laFormula < 0.2 and numWorkers > min_worker ->
        Lab2P1W2.WorkerPool.removeWorker()
      true ->
        :no_change
    end
    Process.send_after(self(), :manage, time_check)
    {:noreply, {time_check, max_worker, min_worker}}
  end
end

defmodule Lab2P1W3.BadWordChecker do
  def checkAndChange(tweet) do
    jason = File.read!("lib/bad-words.json")
    bad_words = Jason.decode!(jason)
    tweet = Regex.replace(~r/(\w+)/, tweet, fn word ->
      if Enum.member?(bad_words, String.downcase(word)) do
        String.replace(String.downcase(word), ~r/./, "*")
      else
        word
      end
    end)
  end
end
