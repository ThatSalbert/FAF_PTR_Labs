defmodule Laboratory3 do
  use Application

  def start(_type, _args) do
    # MainSupervisor.start_link()
    IO.inspect("Test")
  end
end
