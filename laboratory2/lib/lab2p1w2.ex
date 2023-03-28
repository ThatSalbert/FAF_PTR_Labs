defmodule Lab2P1W2.WorkerPool do
  use Supervisor

  def start_link(min_time, max_time) do
    Supervisor.start_link(__MODULE__, {min_time, max_time}, name: __MODULE__)
  end

  def init({min_time, max_time}) do
    children = [
      %{
        id: :printer1,
        start: {Lab2P1W1.Printer, :start_link, [:printer1, min_time, max_time]}
      },
      %{
        id: :printer2,
        start: {Lab2P1W1.Printer, :start_link, [:printer2, min_time, max_time]}
      },
      %{
        id: :printer3,
        start: {Lab2P1W1.Printer, :start_link, [:printer3, min_time, max_time]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def getNumWorkers() do
    Supervisor.count_children(Lab2P1W2.WorkerPool) |> Map.get(:specs)
  end

  def whichWorkers() do
    IO.inspect(Supervisor.which_children(Lab2P1W2.WorkerPool))
    Supervisor.which_children(Lab2P1W2.WorkerPool)
  end

  def addWorker() do
    id = getNumWorkers() + 1
    Supervisor.start_child(Lab2P1W2.WorkerPool, %{
      id: "printer#{id}",
      start: {Lab2P1W1.Printer, :start_link, [:"printer#{id}", 10, 50]}
    })
    IO.inspect("Added worker printer#{id}")
  end

  def removeWorker() do
    workers = whichWorkers() |> Enum.map(fn {id, _, _, _} -> id end)
    Supervisor.terminate_child(Lab2P1W2.WorkerPool, List.first(workers))
    Supervisor.delete_child(Lab2P1W2.WorkerPool, List.first(workers))
    IO.inspect("Removed worker #{List.first(workers)}")
  end
end

defmodule Lab2P1W2.WorkerPoolSupervisor do
  use Supervisor

  def start_link(min_time, max_time) do
    Supervisor.start_link(__MODULE__, {min_time, max_time})
  end

  def init({min_time, max_time}) do
    children = [
      %{
        id: :workerPool,
        start: {Lab2P1W2.WorkerPool, :start_link, [min_time, max_time]}
      },
      %{
        id: :reader1,
        start: {Lab2P1W1.Reader, :start_link, [:reader1, "http://localhost:4000/tweets/1"]}
      },
      %{
        id: :reader2,
        start: {Lab2P1W1.Reader, :start_link, [:reader2, "http://localhost:4000/tweets/2"]}
      },
      %{
        id: :hashtagPrinter,
        start: {Lab2P1W1.HashtagPrinter, :start_link, []}
      },
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Lab2P1W2.LoadBalancer do
  use GenServer

  def start_link() do
    num = Lab2P1W2.WorkerPool.getNumWorkers()
    GenServer.start_link(__MODULE__,  num, name: __MODULE__)
  end

  def init(num) do
    {:ok, {0, num}}
  end

  def handle_info({:tweet, tweet}, {current, _num}) do
    currentNumWorkers = Lab2P1W2.WorkerPool.getNumWorkers()
    id_gen = :"printer#{current + 1}"
    if Process.whereis(id_gen) != nil do
      tweetToSend = Map.get(tweet, "text") |> Lab2P1W3.BadWordChecker.checkAndChange()
      hashtagToSend = Map.get(tweet, "entities") |> Map.get("hashtags") |> Enum.map(fn x -> Map.get(x, "text") end)
      send(id_gen, {:tweet, tweetToSend})
      if(hashtagToSend != []) do
        send(Lab2P1W1.HashtagPrinter, {:tweet, hashtagToSend})
      end
    end
    {:noreply, {rem(current + 1, currentNumWorkers), currentNumWorkers}}
  end

  def handle_info(:panic, {current, _num}) do
    currentNumWorkers = Lab2P1W2.WorkerPool.getNumWorkers()
    id_gen = :"printer#{current + 1}"
    if Process.whereis(id_gen) != nil do
      send(id_gen, :panic)
    end
    {:noreply, {rem(current + 1, currentNumWorkers), currentNumWorkers}}
  end
end
