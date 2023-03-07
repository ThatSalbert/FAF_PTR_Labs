defmodule Laboratory1.Lab1P0W5 do
  def visitWebsite do
    IO.inspect(HTTPoison.get("https://www.google.com/"))
  end
end
