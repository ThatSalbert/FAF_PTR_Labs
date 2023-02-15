defmodule Semaphore do
  def semaphore(num) do
    counter = receive do
      :acquire ->
        if num > 0 do
          IO.puts("Acquired")
          num - 1
        else
          IO.puts("Waiting")
          num
        end
      :release ->
        if num < 1 do
          IO.puts("Released")
          num + 1
        else
          IO.puts("Nothing to release")
          num
        end
    end
    semaphore(counter)
  end

  def acquire(pid) do
    send(pid, :acquire)
  end

  def release(pid) do
    send(pid, :release)
  end
end
