defmodule GenericLoadBalancer do
  use GenServer

  def getTheNumbers() do
    workers = WorkerPoolSupervisor.getWorkers()
    redacterPID = Enum.find(workers, fn {id, _pid} -> id == :workerpoolredacter end) |> elem(1)
    engagementPID = Enum.find(workers, fn {id, _pid} -> id == :workerpoolengagement end) |> elem(1)
    sentimentPID = Enum.find(workers, fn {id, _pid} -> id == :workerpoolsentiment end) |> elem(1)
    numRedacters = Supervisor.count_children(redacterPID) |> Map.get(:specs)
    numEngagement = Supervisor.count_children(engagementPID) |> Map.get(:specs)
    numSentiment = Supervisor.count_children(sentimentPID) |> Map.get(:specs)
    {numRedacters, numEngagement, numSentiment}
  end

  def start_link() do
    {numRedacters, numEngagement, numSentiment} = getTheNumbers()
    GenServer.start_link(__MODULE__, {numRedacters, numEngagement, numSentiment, 0}, name: __MODULE__)
  end

  def init({numRedacters, numEngagement, numSentiment, idCounter}) do
    {:ok, {numRedacters, 0, numEngagement, 0, numSentiment, 0, 0}}
  end

  def handle_info({:tweet, tweet}, {_numRedacters, currentNumRedacters, _numEngagement, currentNumEngagement, _numSentiment, currentNumSentiment, idCounter}) do
    {numRedacters, numEngagement, numSentiment} = getTheNumbers()
    idGenRedacter = :"redacter#{currentNumRedacters + 1}"
    idGenEngagement = :"engagement#{currentNumEngagement + 1}"
    idGenSentiment = :"sentiment#{currentNumSentiment + 1}"
    if Process.whereis(idGenRedacter) != nil do
      hashtagToSend = Map.get(tweet, "entities") |> Map.get("hashtags") |> Enum.map(fn x -> Map.get(x, "text") end)
      if(hashtagToSend != []) do
        send(HashtagPrinter, {:tweet, hashtagToSend})
      end
      send(idGenRedacter, {:tweet, {idCounter, tweet}})
    end
    if Process.whereis(idGenEngagement) != nil do
      send(idGenEngagement, {:tweet, {idCounter, tweet}})
    end
    if Process.whereis(idGenSentiment) != nil do
      send(idGenSentiment, {:tweet, {idCounter, tweet}})
    end
    newIdCounter = idCounter + 1
    {:noreply, {currentNumEngagement, rem(currentNumRedacters + 1, numRedacters), currentNumEngagement, rem(currentNumEngagement + 1, numEngagement), currentNumEngagement, rem(currentNumSentiment + 1, numSentiment), newIdCounter}}
  end

  def handle_info(:panic, {_numRedacters, currentNumRedacters, _numEngagement, currentNumEngagement, _numSentiment, currentNumSentiment, idCounter}) do
    {numRedacters, numEngagement, numSentiment} = getTheNumbers()
    idGenRedacter = :"redacter#{currentNumRedacters + 1}"
    idGenEngagement = :"engagement#{currentNumEngagement + 1}"
    idGenSentiment = :"sentiment#{currentNumSentiment + 1}"
    if Process.whereis(idGenRedacter) != nil do
      send(idGenRedacter, :panic)
    end
    if Process.whereis(idGenEngagement) != nil do
      send(idGenEngagement, :panic)
    end
    if Process.whereis(idGenSentiment) != nil do
      send(idGenSentiment, :panic)
    end
    {:noreply, {currentNumEngagement, rem(currentNumRedacters + 1, numRedacters), currentNumEngagement, rem(currentNumEngagement + 1, numEngagement), currentNumEngagement, rem(currentNumSentiment + 1, numSentiment), idCounter}}
  end
end
