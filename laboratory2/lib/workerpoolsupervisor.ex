defmodule WorkerPoolSupervisor do
  use Supervisor

  def start_link(min_time, max_time, batchSize, batchWaitTime) do
    Supervisor.start_link(__MODULE__, {min_time, max_time, batchSize, batchWaitTime}, name: __MODULE__)
  end

  def init({min_time, max_time, batchSize, batchWaitTime}) do
    children = [
        %{
          id: :reader1,
          start: {Reader, :start_link, [:reader1, "http://localhost:4000/tweets/1"]}
        },
        %{
          id: :reader2,
          start: {Reader, :start_link, [:reader2, "http://localhost:4000/tweets/2"]}
        },
        %{
          id: :emotionreader,
          start: {EmotionReader, :start_link, [:emotionreader, "http://localhost:4000/emotion_values"]}
        },
        %{
          id: :hashtagPrinter,
          start: {HashtagPrinter, :start_link, []}
        },
        %{
          id: :workerpoolsentiment,
          start: {GenericSupervisor, :start_link, ["sentiment", SentimentCalculator, min_time, max_time, 3, :workerpoolsentiment]}
        },
        %{
          id: :workerpoolredacter,
          start: {GenericSupervisor, :start_link, ["redacter", Redacter, min_time, max_time, 3, :workerpoolredacter]}
        },
        %{
          id: :workerpoolengagement,
          start: {GenericSupervisor, :start_link, ["engagement", EngagementCalculator, min_time, max_time, 3, :workerpoolengagement]}
        },
        %{
          id: :usersentimentprinter,
          start: {UserSentimentPrinter, :start_link, []}
        },
        %{
          id: :batcher,
          start: {Batcher, :start_link, [batchSize, batchWaitTime]}
        },
        %{
          id: :aggregator,
          start: {Aggregator, :start_link, [min_time, max_time]}
        }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def whichWorkers() do
    Supervisor.which_children(WorkerPoolSupervisor)
  end

  def getWorkers() do
    workers = whichWorkers() |> Enum.map(fn {id, pid, _, _} -> {id, pid} end)
    workers
  end

  def getSpecificWorker(idtofind) do
    workers = getWorkers()
    worker = Enum.find(workers, fn {id, _} -> id == idtofind end) |> elem(1)
    worker
  end
end
