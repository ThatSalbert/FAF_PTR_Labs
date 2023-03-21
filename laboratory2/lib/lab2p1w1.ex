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
      tweet = Map.get(response, "message") |> Map.get("tweet") |> Map.get("text")
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
    IO.puts "#{name}: #{inspect tweet}"
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
        id: Lab2P1W1.Printer,
        start: {Lab2P1W1.Printer, :start_link, [:printer1, min_time, max_time]}
      },
      %{
        id: Lab2P1W1.Reader1,
        start: {Lab2P1W1.Reader, :start_link, [:reader1, "http://localhost:4000/tweets/1"]}
      },
      %{
        id: Lab2P1W1.Reader2,
        start: {Lab2P1W1.Reader, :start_link, [:reader2, "http://localhost:4000/tweets/2"]}
      },
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
