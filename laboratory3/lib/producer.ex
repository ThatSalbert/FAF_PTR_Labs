defmodule Producer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    IO.inspect("Producer started")
    {:ok, nil}
  end
end
