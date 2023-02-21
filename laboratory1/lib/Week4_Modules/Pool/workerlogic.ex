defmodule WorkerLogic do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def workerEcho(pid, message) do
    GenServer.call(pid, {:workerEcho, message})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:workerEcho, message}, _from, state) do
    echo = "Worker says: " <> message
    {:reply, echo, state}
  end
end
