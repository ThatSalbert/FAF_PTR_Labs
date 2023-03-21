defmodule Lab2P1W2.WorkerPool do
  use Supervisor

  def start_link(min_time, max_time) do
    Supervisor.start_link(__MODULE__, {min_time, max_time}, name: __MODULE__)
  end

  def init({min_time, max_time}) do
    children = [
      %{
        id: :printer1,
        start: {Lab2P1W1.Printer, :start_link, [:printer1, min_time, max_time]}
      },
      %{
        id: :printer2,
        start: {Lab2P1W1.Printer, :start_link, [:printer2, min_time, max_time]}
      },
      %{
        id: :printer3,
        start: {Lab2P1W1.Printer, :start_link, [:printer3, min_time, max_time]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Lab2P1W2.WorkerPoolSupervisor do
  use Supervisor

  def start_link(min_time, max_time) do
    Supervisor.start_link(__MODULE__, {min_time, max_time})
  end

  def init({min_time, max_time}) do
    children = [
      %{
        id: Lab2P1W2.WorkerPool,
        start: {Lab2P1W2.WorkerPool, :start_link, [min_time, max_time]}
      },
      %{
        id: Lab2P1W2.Reader1,
        start: {Lab2P1W1.Reader, :start_link, [:reader1, "http://localhost:4000/tweets/1"]}
      },
      %{
        id: Lab2P1W2.Reader2,
        start: {Lab2P1W1.Reader, :start_link, [:reader2, "http://localhost:4000/tweets/2"]}
      },
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Lab2P1W2.LoadBalancer do
  use GenServer

  def start_link(num) do
    GenServer.start_link(__MODULE__, num, name: __MODULE__)
  end

  def init(num) do
    {:ok, {0, num}}
  end

  def handle_info({:tweet, tweet}, {current, num}) do
    id_gen = :"printer#{current + 1}"
    if Process.whereis(id_gen) != nil do
      send(id_gen, {:tweet, tweet})
    end
    {:noreply, {rem(current + 1, num), num}}
  end

  def handle_info(:panic, {current, num}) do
    id_gen = :"printer#{current + 1}"
    if Process.whereis(id_gen) != nil do
      send(id_gen, :panic)
    end
    {:noreply, {rem(current + 1, num), num}}
  end
end
