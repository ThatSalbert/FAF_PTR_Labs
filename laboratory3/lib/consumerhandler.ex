defmodule ConsumerHandler do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    IO.inspect("ConsumerHandler started")
    {:ok, nil}
  end
end
