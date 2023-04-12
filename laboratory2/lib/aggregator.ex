defmodule Aggregator do
  use GenServer

  def start_link(min_time, max_time) do
    GenServer.start_link(__MODULE__, {min_time, max_time, []}, name: __MODULE__)
  end

  def init({min_time, max_time, aggregatorList}) do
    Process.send_after(self(), :sendToBatcher, 10)
    {:ok, {min_time, max_time, aggregatorList}}
  end

  def handle_info({:addToList, {id, type, theElement}}, {min_time, max_time, aggregatorList}) do
    aggregatorList = aggregatorList ++ [[id, type, theElement]]
    {:noreply, {min_time, max_time, aggregatorList}}
  end

  def handle_info(:sendToBatcher, {min_time, max_time, aggregatorList}) do
    time = :rand.uniform(max_time - min_time) + min_time
    Process.sleep(time)
    aggregatorList = Enum.reject(aggregatorList, fn(x) ->
      if Enum.at(x, 1) == "tweet" do
        tweetToSend = Enum.at(x, 2)
        sentimentToSend = Enum.filter(aggregatorList, fn(y) -> Enum.at(y, 0) == Enum.at(x, 0) and Enum.at(y, 1) == "sentiment" end) |> Enum.fetch(0)
        engagementToSend = Enum.filter(aggregatorList, fn(y) -> Enum.at(y, 0) == Enum.at(x, 0) and Enum.at(y, 1) == "engagement" end) |> Enum.fetch(0)
        sentimentToSend = case sentimentToSend do
          {:ok, value} -> value
          _ -> nil
        end
        engagementToSend = case engagementToSend do
          {:ok, value} -> value
          _ -> nil
        end
        if sentimentToSend != nil and engagementToSend != nil do
          send(Batcher, {:tweet, {Enum.at(x, 0), tweetToSend, Enum.at(sentimentToSend, 2), Enum.at(engagementToSend, 2)}})
          true
        else
          false
        end
      else
        false
      end
    end)
    Process.send_after(self(), :sendToBatcher, time)
    {:noreply, {min_time, max_time, aggregatorList}}
  end
end
