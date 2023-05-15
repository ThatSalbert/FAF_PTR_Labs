defmodule ProducerSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init do
    children = [
      %{
        id: :producer1,
        start: {Producer, :start_link, []}
      },
      %{
        id: :producer2,
        start: {Producer, :start_link, []}
      },
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
