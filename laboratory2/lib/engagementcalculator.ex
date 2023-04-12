defmodule EngagementCalculator do
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
    followerCount = Map.get(tweet, "user") |> Map.get("followers_count")
    retweetCount = if Map.get(tweet, "retweeted_status") == nil do
      Map.get(tweet, "retweet_count")
    else
      Map.get(tweet, "retweeted_status") |> Map.get("retweet_count")
    end
    favoriteCount = if Map.get(tweet, "retweeted_status") == nil do
      Map.get(tweet, "favorite_count")
    else
      Map.get(tweet, "retweeted_status") |> Map.get("favorite_count")
    end

    if followerCount != 0 do
      engagement = (retweetCount + favoriteCount) / followerCount |> Float.ceil(2)
      send(Aggregator, {:addToList, {id, "engagement", engagement}})
    else
      send(Aggregator, {:addToList, {id, "engagement", 0.0}})
    end
    {:noreply, {name, min_time, max_time}}
  end

  def init({name, min_time, max_time}) do
    {:ok, {name, min_time, max_time}}
  end
end
