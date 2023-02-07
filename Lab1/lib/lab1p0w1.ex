defmodule Lab1P0W1 do
  def print_ptr() do
    IO.puts "Hello PTR"
  end

  def isPrime(2), do: true
  def isPrime(n) do
    result = Enum.any?(2..n-1, fn i -> rem(n, i) == 0 end)
    !result
  end

  def cylinderArea(r, h) do
    Float.ceil(2*:math.pi()*r*(r + h), 4)
  end

  def reverse(list) do
    Enum.reverse(list)
  end

  def uniqueSum(list) do
    Enum.uniq(list) |> Enum.sum()
  end

  def extractRandomN(list, n) do
    Enum.take_random(list, n)
  end

  def firstFibonacciElements(1), do: [1]
  def firstFibonacciElements(2), do: [1, 1]
  def firstFibonacciElements(n) do
    previous = firstFibonacciElements(n-1)
    Enum.map(previous, fn x -> x end) ++ [Enum.at(previous, -1) + Enum.at(previous, -2)]
  end

  def translator(dictionary, original_string) do
    String.replace(original_string, ~r/\b\w+\b/, fn word ->
      Map.get(dictionary, String.to_atom(word), word)
    end)
  end

  def smallestNumber(0, 0, 0), do: [0, 0, 0] |> Enum.join()
  def smallestNumber(n1, n2, n3) do
    list = [n1, n2, n3] |> Enum.sort()
    if Enum.at(list, 0) == 0 do
      if Enum.at(list, 1) == 0 do
          [Enum.at(list, 2), Enum.at(list, 1), Enum.at(list, 0)] |> Enum.join()
      else
          [Enum.at(list, 1), Enum.at(list, 0), Enum.at(list, 2)] |> Enum.join()
      end
    else
      [Enum.at(list, 0), Enum.at(list, 1), Enum.at(list, 2)] |> Enum.join()
    end
  end

  def rotateLeft(list, n) do
    {left, right} = Enum.split(list, n)
    right ++ left
  end

  def listRightAngleTriangles() do
    Enum.reduce(1..20, [], fn a, acc ->
      Enum.reduce(1..20, acc, fn b, acc ->
        Enum.reduce(1..28, acc, fn c, acc ->
          if :math.pow(a, 2) + :math.pow(b, 2) == :math.pow(c, 2) do
            acc ++ [[a, b, c]]
          else
            acc
          end
        end)
      end)
    end)
  end

  def removeConsecutiveDuplicates(list) do
    Enum.reduce(list, [], fn n, acc ->
      if Enum.at(acc, -1) == n do
        acc
      else
        acc ++ [n]
      end
    end)
  end

  def lineWords(list) do
    line1 = "qwertyuiopQWERTYUIOP"
    line2 = "asdfghjklASDFGHJKL"
    line3 = "zxcvbnmZXCVBNM"
    lines = [String.graphemes(line1), String.graphemes(line2), String.graphemes(line3)]

    Enum.reduce(list, [], fn word, acc ->
      Enum.reduce(lines, acc, fn line, acc ->
        if Enum.all?(String.graphemes(word), fn char -> Enum.member?(line, char) end) do
          acc ++ [word]
        else
          acc
        end
      end)
    end)
  end

  def encode(word, n) do
    alphabet = String.graphemes("abcdefghijklmnopqrstuvwxyz")
    word = String.graphemes(String.downcase(word))
    Enum.reduce(word, [], fn char, acc ->
      if Enum.member?(alphabet, char) do
        index = Enum.find_index(alphabet, fn y -> y == char end)
        acc ++ [Enum.at(alphabet, rem(index + n, 26))]
      else
        acc ++ [char]
      end
    end) |> Enum.join()
  end

  def decode(word, n) do
    alphabet = String.graphemes("abcdefghijklmnopqrstuvwxyz")
    word = String.graphemes(String.downcase(word))
    Enum.reduce(word, [], fn char, acc ->
      if Enum.member?(alphabet, char) do
        index = Enum.find_index(alphabet, fn y -> y == char end)
        acc ++ [Enum.at(alphabet, rem(index - n, 26))]
      else
        acc ++ [char]
      end
    end) |> Enum.join()
  end

  def lettersCombinations(string) do
    nums = %{
      2 => ["a", "b", "c"],
      3 => ["d", "e", "f"],
      4 => ["g", "h", "i"],
      5 => ["j", "k", "l"],
      6 => ["m", "n", "o"],
      7 => ["p", "q", "r", "s"],
      8 => ["t", "u", "v"],
      9 => ["w", "x", "y", "z"]
    }
  end

  @romanMap [
    {1000, "M"},
    {900, "CM"},
    {500, "D"},
    {400, "CD"},
    {100, "C"},
    {90, "XC"},
    {50, "L"},
    {40, "XL"},
    {10, "X"},
    {9, "IX"},
    {5, "V"},
    {4, "IV"},
    {1, "I"}
  ]

  def toRoman(0), do: ""
  def toRoman(n) do
    Enum.reduce(@romanMap, {"", n}, fn {value, roman}, {acc, n} ->
      {acc <> String.duplicate(roman, div(n, value)), rem(n, value)}
    end) |> elem(0)
  end

  def factorize(n) do
    Enum.reduce()
  end
end
