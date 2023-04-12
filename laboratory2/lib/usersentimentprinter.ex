defmodule UserSentimentPrinter do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(userSentimentMap) do
    Process.send_after(self(), :printUsersSentiment, 5000)
    {:ok, userSentimentMap}
  end

  def handle_info(:printUsersSentiment, userSentimentMap) do
    # Enum.reduce(userSentimentMap, fn {user, score}, _ ->
    #   IO.inspect "User #{user} has an average sentiment of #{score}."
    # end)
    Process.send_after(self(), :printUsersSentiment, 5000)
    {:noreply, userSentimentMap}
  end

  def handle_info({:updateUsersSentiment, {user, score}}, userSentimentMap) do
    newUserList = case Map.get(userSentimentMap, user) do
      nil -> Map.put(userSentimentMap, user, score)
      oldScore -> Map.put(userSentimentMap, user, (oldScore + score) / 2)
    end
    {:noreply, newUserList}
  end
end
