defmodule Lab1P0W5 do
  def visitWebsite do
    {:ok, response} = HTTPoison.get("https://quotes.toscrape.com/")
    response
  end

  def extractQuotes(response) do
    {:ok, parsed} = Floki.parse_document(response.body)
    quote_map = Enum.map(
      Floki.find(parsed, "div.quote"),
      fn quote ->
        quote_author = Floki.find(quote, "small.author") |> List.last() |> Floki.text()
        quote_text = Floki.find(quote, "span.text") |> List.last() |> Floki.text() |> String.slice(1..-2)
        quote_tags = Floki.find(quote, "div.tags a.tag") |> Enum.map(fn tag -> Floki.text(tag) end) |> Enum.join(", ")
        %{quote_author: quote_author, quote_text: quote_text, quote_tags: quote_tags}
      end
    )
    quote_map
  end

  def mapToJson(quote_map) do
    json_data = Jason.encode!(quote_map) |> Jason.Formatter.pretty_print()
    File.write("quotes.json", json_data)
  end
end
