defmodule Batcher do
  use GenServer

  def start_link(batch_size, time_to_wait) do
    ticks = time_to_wait / 1000 |> trunc
    GenServer.start_link(__MODULE__, {batch_size, time_to_wait, [], ticks}, name: __MODULE__)
  end

  def init({batch_size, time_to_wait, messagesToPrintMap, ticks}) do
    Process.send_after(self(), {:timerTick, time_to_wait}, 0)
    {:ok, {batch_size, time_to_wait, messagesToPrintMap, ticks}}
  end

  def handle_info(:printMessagesIfNotFull, {batch_size, time_to_wait, messagesToPrintMap, ticks}) do
    cond do
      Enum.count(messagesToPrintMap) != batch_size ->
        IO.inspect("Printing because time is up")
        IO.puts("")
        Enum.reduce(messagesToPrintMap, fn tweet, _ ->
          IO.inspect tweet
        end)
        newMessagesToPrintMap = List.delete(messagesToPrintMap, messagesToPrintMap)
        ticksCalc = time_to_wait / 1000 |> trunc
        send(self(), {:setTicks, ticksCalc})
        {:noreply, {batch_size, time_to_wait, newMessagesToPrintMap, ticks}}
      length(messagesToPrintMap) == batch_size ->
        {:noreply, {batch_size, time_to_wait, messagesToPrintMap, ticks}}
    end
  end

  def handle_info({:tweet, {id, tweet, sentiment, engagement}}, {batch_size, time_to_wait, messagesToPrintMap, ticks}) do
    messagesToPrint = "Tweet: #{tweet} | Sentiment: #{sentiment} | Engagement: #{engagement} | ID: #{id}"
    newMessagesToPrintMap = messagesToPrintMap ++ [messagesToPrint]
    currentMap = if length(newMessagesToPrintMap) == batch_size do
      IO.inspect("Printing because batch size")
      IO.puts("")
      Enum.reduce(newMessagesToPrintMap, fn tweet, _ ->
        IO.inspect tweet
      end)
      newMessagesToPrintMap = []
      ticksCalc = time_to_wait / 1000 |> trunc
      send(self(), {:setTicks, ticksCalc})
      newMessagesToPrintMap
    else
      newMessagesToPrintMap
    end
    {:noreply, {batch_size, time_to_wait, currentMap, ticks}}
  end

  def handle_info({:setTicks, setTheTicks}, state) do
    send(self(), {:timerTick, setTheTicks})
    {:noreply, state}
  end

  def handle_info({:timer, currentTick}, state) do
    newTick = currentTick - 1
    if newTick == 0 do
      send(self(), :printMessagesIfNotFull)
      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  def handle_info({:timerTick, newTick}, state) do
    newTick = newTick - 1
    Process.sleep(1000)
    send(self(), {:timerTick, newTick})
    send(self(), {:timer, newTick})
    {:noreply, state}
  end
end
