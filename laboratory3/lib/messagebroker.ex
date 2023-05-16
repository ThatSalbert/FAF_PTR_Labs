defmodule MessageBroker do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:subscribe, topic, socket}, _from, state) do
    keys = Map.keys(state)
    if (Enum.member?(keys, topic)) do
      case Map.get(state, topic) do
        nil ->
          new_state = Map.put(state, topic, [socket])
          IO.inspect(new_state)
          {:reply, :ok, new_state}
        subscribers ->
          if (Enum.member?(subscribers, socket)) do
            {:reply, :error, state}
          else
            new_state = Map.put(state, topic, [socket | subscribers])
            IO.inspect(new_state)
            {:reply, :ok, new_state}
          end
      end
    else
      {:reply, :error, state}
    end
  end

  def handle_call({:unsubscribe, topic, socket}, _from, state) do
    keys = Map.keys(state)
    if (Enum.member?(keys, topic)) do
      case Map.get(state, topic) do
        nil ->
          {:reply, :error, state}
        subscribers ->
          if (Enum.member?(subscribers, socket)) do
            new_state = Map.put(state, topic, Enum.reject(subscribers, fn subscriber -> subscriber == socket end))
            IO.inspect(new_state)
            {:reply, :ok, new_state}
          else
            {:reply, :error, state}
          end
      end
    else
      {:reply, :error, state}
    end
  end

  def handle_call(:get_list, _from, state) do
    topic_list = Map.keys(state)
    {:reply, topic_list, state}
  end

  def handle_cast({:message, message}, state) do
    decoded = Poison.decode!(message)
    topic = Map.get(decoded, "topic")
    message_unmodified = Map.get(decoded, "message")
    message_body = message_unmodified <> "\r\n"

    subscribers = Map.get(state, topic, [])

    if (length(subscribers) == 0) do
      new_state = Map.put(state, topic, [])
      {:noreply, new_state}
    else
      Enum.each(subscribers, fn socket ->
        :gen_tcp.send(socket, message_body)
      end)
      {:noreply, state}
    end
  end

  def subscribe(topic, socket) do
    GenServer.call(__MODULE__, {:subscribe, topic, socket})
  end

  def unsubscribe(topic, socket) do
    GenServer.call(__MODULE__, {:unsubscribe, topic, socket})
  end

  def send_message(message) do
    GenServer.cast(__MODULE__, {:message, message})
  end

  def get_list() do
    GenServer.call(__MODULE__, :get_list)
  end
end
