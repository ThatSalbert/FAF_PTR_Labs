defmodule Laboratory2 do
  use Application

  def start(_type, _args) do
    min_time = 10
    max_time = 50
    {:ok, _} = Lab2P1W2.WorkerPoolSupervisor.start_link(min_time, max_time)
    {:ok, _} = Lab2P1W2.LoadBalancer.start_link()
    {:ok, _} = Lab2P1W3.Manager.start_link(5000, 7, 1)
  end
end
