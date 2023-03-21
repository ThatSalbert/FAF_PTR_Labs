defmodule Laboratory2 do
  use Application

  def start(_type, _args) do
    min_time = 1000
    max_time = 2000
    num = 3
    {:ok, _} = Lab2P1W2.WorkerPoolSupervisor.start_link(min_time, max_time)
    {:ok, _} = Lab2P1W2.LoadBalancer.start_link(num)
  end
end
