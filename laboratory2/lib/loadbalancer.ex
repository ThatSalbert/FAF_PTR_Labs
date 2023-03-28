defmodule LoadBalancer do
  use GenServer

  def start_link() do
    num = WorkerPool.getNumWorkers()
    GenServer.start_link(__MODULE__,  num, name: __MODULE__)
  end

  def init(num) do
    {:ok, {0, num}}
  end

  def handle_info({:tweet, tweet}, {current, _num}) do
    currentNumWorkers = WorkerPool.getNumWorkers()
    id_gen = :"printer#{current + 1}"
    if Process.whereis(id_gen) != nil do
      tweetToSend = Map.get(tweet, "text") |> BadWordChecker.checkAndChange()
      hashtagToSend = Map.get(tweet, "entities") |> Map.get("hashtags") |> Enum.map(fn x -> Map.get(x, "text") end)
      send(id_gen, {:tweet, tweetToSend})
      if(hashtagToSend != []) do
        send(HashtagPrinter, {:tweet, hashtagToSend})
      end
    end
    {:noreply, {rem(current + 1, currentNumWorkers), currentNumWorkers}}
  end

  def handle_info(:panic, {current, _num}) do
    currentNumWorkers = WorkerPool.getNumWorkers()
    id_gen = :"printer#{current + 1}"
    if Process.whereis(id_gen) != nil do
      send(id_gen, :panic)
    end
    {:noreply, {rem(current + 1, currentNumWorkers), currentNumWorkers}}
  end
end
