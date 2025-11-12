defmodule SalesTest do
  use ExUnit.Case
  doctest Sales

  test "greets the world" do
    assert Sales.hello() == :world
  end
end
