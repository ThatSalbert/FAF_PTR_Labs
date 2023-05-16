defmodule MessageBroker do
  use GenServer
  use AMQP

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, }
  end
end
