defmodule MessageBrokerSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init do
    children = [
      %{
        id: :consumerhandler,
        start: {ConsumerHandler, :start_link, []}
      },
      %{
        id: :producerhandler,
        start: {ProducerHandler, :start_link, []}
      },
      %{
        id: :messagebroker,
        start: {MessageBroker, :start_link, []}
      }
    ]

    IO.inspect("MessageBrokerSupervisor started")
    Supervisor.init(children, strategy: :one_for_one)
  end
end
