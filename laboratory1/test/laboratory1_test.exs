defmodule Laboratory1Test do
  use ExUnit.Case

  import ExUnit.CaptureIO

  test "Prints: Hello PTR" do
    lab1_res = capture_io(fn -> Lab1P0W1.print_ptr() end)
    assert lab1_res == "Hello PTR\n"
  end

  test "Checks if the given number is prime" do
    result = Lab1P0W2.isPrime(2)
    assert result == true

    result = Lab1P0W2.isPrime(3)
    assert result == true

    result = Lab1P0W2.isPrime(281)
    assert result == true

    result = Lab1P0W2.isPrime(923)
    assert result == false
  end

  test "Calculates the total area of a cylinder" do
    result = Lab1P0W2.cylinderArea(4, 3)
    assert result == 175.9292

    result = Lab1P0W2.cylinderArea(11, 7)
    assert result == 1244.0707

    result = Lab1P0W2.cylinderArea(19, 3)
    assert result == 2626.3715
  end

  test "Reverses given list" do
    result = Lab1P0W2.reverse([1, 2, 3, 4, 5])
    assert result == [5, 4, 3, 2, 1]

    result = Lab1P0W2.reverse([19, -1, 9, 2, 0])
    assert result == [0, 2, 9, -1, 19]
  end

  test "Calculates the sum of unique elements in a list" do
    result = Lab1P0W2.uniqueSum([1, 2, 3, 4, 5])
    assert result == 15

    result = Lab1P0W2.uniqueSum([1, 2, 2, 3, 4, 5, 5, 1, 2, 3, 4, 5])
    assert result == 15

    result = Lab1P0W2.uniqueSum([1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 6, 8, 8, 10, 12, 11, 20])
    assert result == 82
  end

  test "Returns the first n elements of the Fibonacci sequence" do
    result = Lab1P0W2.firstFibonacciElements(1)
    assert result == [1]

    result = Lab1P0W2.firstFibonacciElements(2)
    assert result == [1, 1]

    result = Lab1P0W2.firstFibonacciElements(3)
    assert result == [1, 1, 2]

    result = Lab1P0W2.firstFibonacciElements(4)
    assert result == [1, 1, 2, 3]

    result = Lab1P0W2.firstFibonacciElements(5)
    assert result == [1, 1, 2, 3, 5]

    result = Lab1P0W2.firstFibonacciElements(6)
    assert result == [1, 1, 2, 3, 5, 8]

    result = Lab1P0W2.firstFibonacciElements(7)
    assert result == [1, 1, 2, 3, 5, 8, 13]

    result = Lab1P0W2.firstFibonacciElements(8)
    assert result == [1, 1, 2, 3, 5, 8, 13, 21]

    result = Lab1P0W2.firstFibonacciElements(9)
    assert result == [1, 1, 2, 3, 5, 8, 13, 21, 34]
  end

  test "Translates a sentece" do
    dictionary = %{
      mama: "mother",
      papa: "father"
    }
    original_string = "mama is with papa"
    result = Lab1P0W2.translator(dictionary, original_string)
    assert result == "mother is with father"
  end

  test "Returns smallest number from 3 given digits" do
    result = Lab1P0W2.smallestNumber(0, 0, 0)
    assert result == "000"

    result = Lab1P0W2.smallestNumber(0, 5, 1)
    assert result == "105"

    result = Lab1P0W2.smallestNumber(5, 1, 5)
    assert result == "155"

    result = Lab1P0W2.smallestNumber(7, 0, 0)
    assert result == "700"

    result = Lab1P0W2.smallestNumber(1, 2, 3)
    assert result == "123"
  end

  test "Rotate list n places to the left" do
    result = Lab1P0W2.rotateLeft([1, 2, 3, 4, 5], 2)
    assert result == [3, 4, 5, 1, 2]

    result = Lab1P0W2.rotateLeft([9, 1, 5, 9, 5, 8], 3)
    assert result == [9, 5, 8, 9, 1, 5]
  end

  test "Eliminate conseuctive duplicates in a given list" do
    result = Lab1P0W2.removeConsecutiveDuplicates([1, 2, 2, 3, 2, 4, 4, 3, 4, 5, 5, 4, 5, 5])
    assert result == [1, 2, 3, 2, 4, 3, 4, 5, 4, 5]

    result = Lab1P0W2.removeConsecutiveDuplicates([1, 2, 2, 2, 4, 8, 4])
    assert result == [1, 2, 4, 8, 4]
  end
end
