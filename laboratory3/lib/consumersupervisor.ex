defmodule ConsumerSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init do
    children = [
      %{
        id: :consumer1,
        start: {Consumer, :start_link, []}
      },
      %{
        id: :consumer2,
        start: {Consumer, :start_link, []}
      },
    ]

    IO.inspect("ConsumerSupervisor started")
    Supervisor.init(children, strategy: :one_for_one)
  end
end
