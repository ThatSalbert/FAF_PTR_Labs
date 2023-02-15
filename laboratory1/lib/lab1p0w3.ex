defmodule Lab1P0W3 do

  def actorPrints do
    receive do
      message ->
        IO.puts message
    end
    actorPrints()
  end

  def actorModify do
    receive do
      {:integer, message} ->
        IO.puts ("Received: " <> to_string(message + 1))
      {:string, message} ->
        IO.puts ("Received: " <> String.upcase(message))
      {_, _} ->
        IO.puts("Received: What do I do with this?")
    end
    actorModify()
  end

  def actorKill do
    exit(:kill)
  end

  def actorMonitor do
    spawn_monitor(fn -> Lab1P0W3.actorKill() end)
    receive do
      {:DOWN, _, _, _, reason} ->
        IO.puts("Actor killed. Reason: " <> to_string(reason))
    end
  end

  def actorAverager(num) do
    average = receive do
      value ->
        calc = Float.round((num + value) / 2, 3)
        IO.puts("Current average: " <> to_string(calc))
        calc
      end
    actorAverager(average)
  end

  def newQueue() do
    pid = spawn(fn -> Queue.queue([]) end)
    pid
  end

  def createSemaphore(num) do
    semaphore = spawn(fn -> Semaphore.semaphore(num) end)
    semaphore
  end
end
