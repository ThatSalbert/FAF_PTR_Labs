defmodule Laboratory2 do
  use Application

  def start(_type, _args) do
    min_time = 10
    max_time = 50
    {:ok, _} = WorkerPoolSupervisor.start_link(min_time, max_time)
    {:ok, _} = LoadBalancer.start_link()
    {:ok, _} = Manager.start_link(5000, 7, 1)
  end
end
