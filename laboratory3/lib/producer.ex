defmodule Producer do
  use Task
  require Logger

  def start_link(port) do
    Task.start_link(__MODULE__, :run, [port])
  end

  def run(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Producer started")
    loop(socket)
  end

  def loop(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, client_socket} ->
        Logger.info("Producer accepted")
        {:ok, pid} = ProducerHandler.start_link()
        :ok = :gen_tcp.controlling_process(client_socket, pid)
        ProducerHandler.handle_stuff(client_socket)
        loop(socket)
      {:error, reason} ->
        Logger.info("Producer error: #{reason}")
    end
  end
end
