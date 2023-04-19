defmodule Batcher do
  use GenServer

  def start_link(batch_size, time_to_wait) do
    GenServer.start_link(__MODULE__, {batch_size, time_to_wait, [], System.system_time(:millisecond)}, name: __MODULE__)
  end

  def init({batch_size, time_to_wait, messagesToPrintMap, currentTick}) do
    {:ok, {batch_size, time_to_wait, messagesToPrintMap, currentTick}}
  end

  def handle_info({:tweet, {id, tweet, sentiment, engagement}}, {batch_size, time_to_wait, messagesToPrintMap, currentTick}) do
    tick = currentTick
    tickNow = System.system_time(:millisecond)
    tickDiff = tickNow - tick
    messagesToPrint = "Tweet: #{tweet} | Sentiment: #{sentiment} | Engagement: #{engagement} | ID: #{id}"
    newMessagesToPrintMap = messagesToPrintMap ++ [messagesToPrint]
    {currentMap, ticks} = cond do
      length(newMessagesToPrintMap) == batch_size and tickDiff < time_to_wait ->
        IO.puts("Printing because full")
        IO.puts("")
        Enum.reduce(newMessagesToPrintMap, fn tweet, _ ->
          IO.inspect tweet
        end)
        ticksCalc = System.system_time(:millisecond)
        {[], ticksCalc}
      tickDiff >= time_to_wait ->
        IO.puts("Printing because timer")
        IO.puts("")
        Enum.reduce(newMessagesToPrintMap, fn tweet, _ ->
          IO.inspect tweet
        end)
        ticksCalc = System.system_time(:millisecond)
        {[], ticksCalc}
      true ->
        {newMessagesToPrintMap, tick}
    end
    {:noreply, {batch_size, time_to_wait, currentMap, ticks}}
  end
end
