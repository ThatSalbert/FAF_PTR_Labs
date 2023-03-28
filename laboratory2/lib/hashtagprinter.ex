defmodule HashtagPrinter do
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
