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

  def queue(queueList) do
    newQueueList = receive do
      :show ->
        IO.inspect(queueList)
        queueList
      {:push, value} ->
        IO.puts("Pushed: " <> to_string(value))
        [value | queueList]
      :pop ->
        IO.puts("Popped: " <> to_string(List.last(queueList)))
        List.delete_at(queueList, -1)
    end
    queue(newQueueList)
  end

  def show(pid) do
    send(pid, :show)
  end

  def push(pid, value) do
    send(pid, {:push, value})
  end

  def pop(pid) do
    send(pid, :pop)
  end

  def newQueue() do
    pid = spawn(fn -> Lab1P0W3.queue([]) end)
    pid
  end

  def semaphore(num) do
    semaphoreCounter = receive do
      :acquire ->
        if num > 0 do
          IO.puts("Semaphore acquired")
          num - 1
        else
          IO.puts("Semaphore not acquired")
          num
        end
      :release ->
        IO.puts("Semaphore released")
        num + 1
    end
    semaphore(semaphoreCounter)
  end

  def acquire(pid) do
    send(pid, :acquire)
  end

  def release(pid) do
    send(pid, :release)
  end

  def createSemaphore(num) do
    semaphore = spawn(fn -> Lab1P0W3.semaphore(num) end)
    semaphore
  end
end
