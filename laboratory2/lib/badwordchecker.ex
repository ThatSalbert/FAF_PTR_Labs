defmodule BadWordChecker do
  def checkAndChange(tweet) do
    jason = File.read!("lib/bad-words.json")
    bad_words = Jason.decode!(jason)
    tweet = Regex.replace(~r/(\w+)/, tweet, fn word ->
      if Enum.member?(bad_words, String.downcase(word)) do
        String.replace(String.downcase(word), ~r/./, "*")
      else
        word
      end
    end)
  end
end
