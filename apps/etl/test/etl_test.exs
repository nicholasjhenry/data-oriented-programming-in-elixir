defmodule EtlTest do
  use ExUnit.Case
  doctest Etl

  test "greets the world" do
    assert Etl.hello() == :world
  end
end
