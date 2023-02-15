defmodule Semaphore do
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
end
