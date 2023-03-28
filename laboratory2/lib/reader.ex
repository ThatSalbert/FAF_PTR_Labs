defmodule Reader do
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
    send(LoadBalancer, :panic)
    {:noreply, nil}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: chunk}, _state) do
    "event: \"message\"\n\ndata: " <> message = chunk
    {success, response} = Jason.decode(String.trim(message))
    if success == :ok do
      tweet = Map.get(response, "message") |> Map.get("tweet")
      send(LoadBalancer, {:tweet, tweet})

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
