defmodule Redacter do
  use GenServer

  def start_link(name, min_time, max_time) do
    GenServer.start_link(__MODULE__, {name, min_time, max_time}, name: name)
  end

  def handle_info(:panic, {name, min_time, max_time}) do
    #IO.puts "#{name}: Panicked and killed itself."
    exit(:crash)
    {:noreply, {name, min_time, max_time}}
  end

  def handle_info({:tweet, {id, tweet}}, {name, min_time, max_time}) do
    :rand.uniform(max_time - min_time) + min_time |> Process.sleep
    tweetToPrint = Map.get(tweet, "text") |> BadWordChecker.checkAndChange()
    send(Aggregator, {:addToList, {id, "tweet", tweetToPrint}})
    {:noreply, {name, min_time, max_time}}
  end

  def init({name, min_time, max_time}) do
    {:ok, {name, min_time, max_time}}
  end
end
