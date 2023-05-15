defmodule Consumer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    IO.inspect("Consumer started")
    {:ok, nil}
  end
end
