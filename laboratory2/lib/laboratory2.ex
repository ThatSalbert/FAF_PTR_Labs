defmodule Laboratory2 do
  use Application

  def start(_type, _args) do
    min_time = 100
    max_time = 500
    batch_size = 25
    batch_time = 10000
    {:ok, _} = WorkerPoolSupervisor.start_link(min_time, max_time, batch_size, batch_time)
    {:ok, _} = GenericLoadBalancer.start_link()
    # {:ok, _} = Manager.start_link(5000, 7, 1)
  end
end
