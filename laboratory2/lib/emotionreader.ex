defmodule EmotionReader do
  use GenServer

  def start_link(name, url) do
    GenServer.start_link(__MODULE__, url, name: name)
  end

  def init(url) do
    HTTPoison.get!(url, [], [recv_timeout: :infinity, stream_to: self()])
    {:ok, nil}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: chunk}, state) do
    joinChunk = Enum.join([state, chunk], "")
    {:noreply, joinChunk}
  end

  def handle_info(%HTTPoison.AsyncEnd{} = async_end, state) do
    stream = String.split(state, "\r\n")
    newState = Enum.map(stream, fn x -> String.split(x, "\t") end) |> Map.new(fn [key, value] -> score = String.to_integer(String.at(value, String.length(value) - 1)); {key, score} end)
    {:noreply, newState}
  end

  def handle_call({:getscore, key}, _from, state) do
    valueOfScore = Map.fetch(state, key)
    score = case valueOfScore do
      {:ok, value} -> value
      :error -> 0
    end
    {:reply, score, state}
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
