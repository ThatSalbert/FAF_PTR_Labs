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
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info("Producer accepted")
    {:ok, pid} = Task.Supervisor.start_child(MainProducerSupervisor, ProducerHandler, :handle_stuff, [client])
    :ok = :gen_tcp.controlling_process(client, pid)
    loop(socket)
  end
end
