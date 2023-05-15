defmodule MainSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      %{
        id: :producersupervisor,
        start: {ProducerSupervisor, :start_link, []}
      },
      %{
        id: :consumersupervisor,
        start: {ConsumerSupervisor, :start_link, []}
      },
      %{
        id: :messagebrokersupervisor,
        start: {MessageBrokerSupervisor, :start_link, []}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
