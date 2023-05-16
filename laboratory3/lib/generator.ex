defmodule Generator do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, socket} = :gen_tcp.connect('127.0.0.1', 8000, [:binary, packet: :line, active: false, reuseaddr: true])
    schedule_send(socket)
    {:ok, socket}
  end

  def handle_info(:send, socket) do
    payload = create_message()
    packet = "#{payload |> Poison.Encoder.encode(%{strict_keys: true})}\n"
    :ok = :gen_tcp.send(socket, packet)
    schedule_send(socket)
    {:noreply, socket}
  end

  defp schedule_send(socket) do
    Process.send_after(self(), :send, 2000)
  end

  defp create_message() do
    topics = ["politics", "sports", "technology", "finance", "entertainment", "health", "environment", "science", "education", "crime", "weather", "business"]
    messages = [
      "New government policies affect businesses.",
      "Sports team wins championship title.",
      "Breakthrough technology revolutionizes communication industry.",
      "Economy shows signs of recovery.",
      "Celebrities gather for charity event.",
      "Medical breakthrough offers potential cure.",
      "Environmental activists protest against deforestation.",
      "Scientists discover new species.",
      "Education reforms aim to improve outcomes.",
      "Crime rates reach all-time low.",
      "Severe weather warning issued.",
      "Startup secures major investment funding."
      ]

    topic = Enum.random(topics)
    message = Enum.random(messages)
    %{topic: topic, message: message}
  end
end
