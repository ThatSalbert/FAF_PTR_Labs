defmodule Lab2P1W1.Reader do
  use GenServer

  def start_link(name, url) do
    GenServer.start_link(__MODULE__, url, name: name)
  end

  def init(url) do
    HTTPoison.get!(url, [], [recv_timeout: :infinity, stream_to: self()])
    {:ok, nil}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: ""}, url) do
    HTTPoison.get!(url, [], [recv_timeout: :infinity, stream_to: self()])
    {:noreply, url}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: "event: \"message\"\n\ndata: {\"message\": panic}\n\n"}, _state) do
    send(Lab2P1W2.LoadBalancer, :panic)
    {:noreply, nil}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: chunk}, _state) do
    "event: \"message\"\n\ndata: " <> message = chunk
    {success, response} = Jason.decode(String.trim(message))
    if success == :ok do
      tweet = Map.get(response, "message") |> Map.get("tweet")
      send(Lab2P1W2.LoadBalancer, {:tweet, tweet})

    end
    {:noreply, nil}
  end

  def handle_info(%HTTPoison.AsyncStatus{} = status, _state) do
    IO.puts "Status: #{inspect status}"
    {:noreply, nil}
  end

  def handle_info(%HTTPoison.AsyncHeaders{} = headers, _state) do
    IO.puts "Headers: #{inspect headers}"
    {:noreply, nil}
  end
end

defmodule Lab2P1W1.Printer do
  use GenServer

  def start_link(name, min_time, max_time) do
    GenServer.start_link(__MODULE__, {name, min_time, max_time}, name: name)
  end

  def handle_info({:tweet, tweet}, {name, min_time, max_time}) do
    :rand.uniform(max_time - min_time) + min_time |> Process.sleep
    tweetToPrint = to_string(tweet)
    IO.puts "#{name}: #{tweetToPrint}"
    {:noreply, {name, min_time, max_time}}
  end

  def handle_info(:panic, {name, min_time, max_time}) do
    IO.puts "#{name}: Panicked and killed itself."
    exit(:crash)
    {:noreply, {name, min_time, max_time}}
  end

  def init({name, min_time, max_time}) do
    {:ok, {name, min_time, max_time}}
  end
end

defmodule Lab2P1W1.Supervisor do
  use Supervisor

  def start_link(min_time, max_time) do
    Supervisor.start_link(__MODULE__, {min_time, max_time})
  end

  def init({min_time, max_time}) do
    children = [
      %{
        id: :printer,
        start: {Lab2P1W1.Printer, :start_link, [:printer1, min_time, max_time]}
      },
      %{
        id: :reader1,
        start: {Lab2P1W1.Reader, :start_link, [:reader1, "http://localhost:4000/tweets/1"]}
      },
      %{
        id: :reader2,
        start: {Lab2P1W1.Reader, :start_link, [:reader2, "http://localhost:4000/tweets/2"]}
      },
      %{
        id: :hashtagPrinter,
        start: {Lab2P1W1.HashtagPrinter, :start_link, []}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Lab2P1W1.HashtagPrinter do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(hashtagMap) do
    Process.send_after(self(), :getMostUsedHashtag, 5000)
    {:ok, hashtagMap}
  end

  def handle_info(:getMostUsedHashtag, hashtagMap) do
    {mostUsedHashtag, count} = hashtagMap |> Map.to_list |> Enum.max_by(fn {_, count} -> count end)
    IO.puts("\n")
    IO.inspect "Most used hashtag: #{mostUsedHashtag} with #{count} occurences."
    IO.puts("\n")
    hashtagMap = %{}
    Process.send_after(self(), :getMostUsedHashtag, 5000)
    {:noreply, hashtagMap}
  end

  def handle_info({:tweet, hashtagList}, hashtagMap) do
    hashtagMap = Enum.reduce(hashtagList, hashtagMap, fn hashtag, hashtagMap ->
      case Map.get(hashtagMap, hashtag) do
        nil -> Map.put(hashtagMap, hashtag, 1)
        count -> Map.put(hashtagMap, hashtag, count + 1)
      end
    end)
    {:noreply, hashtagMap}
  end
end
