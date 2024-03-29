defmodule MessageBrokerSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      %{
        id: :message_broker,
        start: {MessageBroker, :start_link, []}
      }
    ]

    IO.inspect("MessageBrokerSupervisor started")
    Supervisor.init(children, strategy: :one_for_one)
  end
end
