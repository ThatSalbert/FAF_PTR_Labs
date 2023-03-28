defmodule SupervisorWeek1 do
  use Supervisor

  def start_link(min_time, max_time) do
    Supervisor.start_link(__MODULE__, {min_time, max_time})
  end

  def init({min_time, max_time}) do
    children = [
      %{
        id: :printer,
        start: {Printer, :start_link, [:printer1, min_time, max_time]}
      },
      %{
        id: :reader1,
        start: {Reader, :start_link, [:reader1, "http://localhost:4000/tweets/1"]}
      },
      %{
        id: :reader2,
        start: {Reader, :start_link, [:reader2, "http://localhost:4000/tweets/2"]}
      },
      %{
        id: :hashtagPrinter,
        start: {HashtagPrinter, :start_link, []}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
