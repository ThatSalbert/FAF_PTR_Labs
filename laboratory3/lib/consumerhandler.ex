defmodule ConsumerHandler do
  require Logger

  def handle_stuff(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        Logger.info("Consumer received: #{data}")
        handle_data(data)
        handle_stuff(socket)
      {:error, :closed} ->
        Logger.info("Producer closed")
      {:error, reason} ->
        Logger.info("Producer error: #{reason}")
    end
  end

  defp handle_data(data) do
    Logger.info("Consumer handled: #{data}")
  end
end
