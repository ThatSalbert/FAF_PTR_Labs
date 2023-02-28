defmodule WorkerSplit do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def workerSplitMessage(pid, msg) do
    IO.puts("Splitting message: #{msg}")
    GenServer.call(pid, {:split, msg})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:split, msg}, _from, state) do
    result = String.split(msg, " ")
    {:reply, result, state}
  end
end

defmodule WorkerReplace do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def workerReplaceMessage(pid, msg) do
    IO.puts("Replacing message: #{msg}")
    GenServer.call(pid, {:replace, msg})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:replace, msg}, _from, state) do
    lowercase = Enum.map(msg, fn part -> String.downcase(part) end)
    result = Enum.map(lowercase, fn part ->
      String.graphemes(part) |> Enum.map(fn char ->
        if String.equivalent?(char, "n") do
          "m"
        else if String.equivalent?(char, "m") do
          "n"
        else
          char
        end
      end
      end) |> Enum.join("")
    end)
    {:reply, result, state}
  end
end

defmodule WorkerJoin do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def workerJoinMessage(pid, msg) do
    IO.puts("Joining message: #{msg}")
    GenServer.call(pid, {:join, msg})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:join, msg}, _from, state) do
    result = Enum.join(msg, " ")
    {:reply, result, state}
  end
end

defmodule SupervisorProcessLine do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      %{
        id: 1,
        start: {WorkerSplit, :start_link, []}
      },
      %{
        id: 2,
        start: {WorkerReplace, :start_link, []}
      },
      %{
        id: 3,
        start: {WorkerJoin, :start_link, []}
      }
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def doWork(pid, message) do
    pidSplit = Supervisor.which_children(pid) |> Enum.find(fn {i, _, _, _} -> i == 1 end) |> elem(1)
    pidReplace = Supervisor.which_children(pid) |> Enum.find(fn {i, _, _, _} -> i == 2 end) |> elem(1)
    pidJoin = Supervisor.which_children(pid) |> Enum.find(fn {i, _, _, _} -> i == 3 end) |> elem(1)
    result = WorkerJoin.workerJoinMessage(pidJoin, WorkerReplace.workerReplaceMessage(pidReplace, WorkerSplit.workerSplitMessage(pidSplit, message)))
    IO.puts("Result: #{result}")
  end


end

{:ok, pid} = SupervisorProcessLine.start_link()
SupervisorProcessLine.doWork(pid, "Om nom nom. It's very tasty.")
