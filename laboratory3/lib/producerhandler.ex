defmodule ProducerHandler do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, nil}
  end

  def handle_stuff(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        Logger.info("Producer received data")
        send_to_messagebroker(data)
        handle_stuff(socket)
      {:error, :closed} ->
        Logger.info("Producer closed")
      {:error, reason} ->
        Logger.info("Producer error: #{reason}")
    end
  end

  defp send_to_messagebroker(data) do
    MessageBroker.send_message(data)
  end
end
