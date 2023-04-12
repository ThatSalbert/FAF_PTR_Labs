defmodule SentimentCalculator do
  use GenServer

  def start_link(name, min_time, max_time) do
    GenServer.start_link(__MODULE__, {name, min_time, max_time}, name: name)
  end

  def handle_info(:panic, {name, min_time, max_time}) do
    #IO.puts "#{name}: Panicked and killed itself."
    exit(:crash)
    {:noreply, {name, min_time, max_time}}
  end

  defp calculatePerUser(pid, tweet) do
    user = Map.get(tweet, "user") |> Map.get("screen_name")
    tweetToProcess = Map.get(tweet, "text") |> String.downcase() |> String.split(" ", trim: true)
    sum = Enum.map(tweetToProcess, fn x -> GenServer.call(pid, {:getscore, x}) end)
    score = Enum.sum(sum) / Enum.count(sum) |> Float.ceil(2)
    {user, score}
  end

  def handle_info({:tweet, {id, tweet}}, {name, min_time, max_time}) do
    :rand.uniform(max_time - min_time) + min_time |> Process.sleep
    {user, score} = calculatePerUser(WorkerPoolSupervisor.getSpecificWorker(:emotionreader), tweet)
    send(UserSentimentPrinter, {:updateUsersSentiment, {user, score}})
    send(Aggregator, {:addToList, {id, "sentiment", score}})
    {:noreply, {name, min_time, max_time}}
  end

  def init({name, min_time, max_time}) do
    {:ok, {name, min_time, max_time}}
  end
end
