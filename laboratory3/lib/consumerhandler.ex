defmodule ConsumerHandler do
  require Logger

  def handle_stuff(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        command = String.trim(data) |> String.split(" ")
        handle_command(command, socket)
        handle_stuff(socket)
      {:error, :closed} ->
        Logger.info("Producer closed")
      {:error, reason} ->
        Logger.info("Producer error: #{reason}")
    end
  end

  defp handle_command(command, socket) do
    user_command = Enum.at(command, 0)
    arg = Enum.at(command, 1)
    case [user_command, arg] do
      ["sub", arg] ->
        if(arg != "") do
          response = MessageBroker.subscribe(arg, socket)
          case response do
            :ok ->
              :gen_tcp.send(socket, "Subscribed to #{arg} \r\n")
            :error ->
              :gen_tcp.send(socket, "You are already subscribed to \"#{arg}\" or doesn't exist \r\n")
          end
        end
      ["unsub", arg] ->
        if(arg != "") do
          response = MessageBroker.unsubscribe(arg, socket)
          case response do
            :ok ->
              :gen_tcp.send(socket, "Unsubscribed from #{arg} \r\n")
            :error ->
              :gen_tcp.send(socket, "You are not subscribed to \"#{arg}\" or doesn't exist \r\n")
          end
        end
      ["get", _] ->
        response = MessageBroker.get_list()
        :gen_tcp.send(socket, "Topics: #{fn() -> Enum.join(response, ", ") end.()} \r\n")
      [_, _] ->
        :gen_tcp.send(socket, "Invalid command \r\n")
    end
  end
end
