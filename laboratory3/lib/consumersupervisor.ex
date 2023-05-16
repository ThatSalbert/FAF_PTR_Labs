defmodule ConsumerSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      {Task.Supervisor, name: MainConsumerSupervisor},
      {Consumer, 8001}
    ]

    IO.inspect("ConsumerSupervisor started")
    Supervisor.init(children, strategy: :one_for_one)
  end
end
