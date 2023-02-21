defmodule Queue do
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
end
