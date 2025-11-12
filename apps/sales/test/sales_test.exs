defmodule SalesTest do
  use ExUnit.Case

  alias Sales.Account
  alias Sales.Sector

  test "rules" do
    Sales.example_rule_1() |> dbg
    Sales.example_rule_2() |> dbg
    Sales.example_rule_3() |> dbg
  end

  test "success: rule for org 111" do
    account = Account.new(1, :amer, :us, Sector.new("finance"), :strategic, :direct)
    Sales.rule_for_org_111(account) |> dbg
  end

  test "fail: rule for org 111" do
    account = Account.new(1, :emea, :ca, Sector.new("finance"), :strategic, :direct)
    Sales.rule_for_org_111(account) |> dbg
  end
end
