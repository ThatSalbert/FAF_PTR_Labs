defmodule Laboratory3 do
  use Application

  def start(_type, _args) do
    MainSupervisor.start_link()
    :timer.sleep(1000)
    Generator.start_link()
  end
end
