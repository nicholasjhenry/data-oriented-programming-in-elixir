defmodule EtlTest do
  use ExUnit.Case

  alias Etl.RawData

  @listing_7_1 [
    RawData.new(1, audit_finding: :out_of_compliance, policy: :flexible, premium?: true),
    RawData.new(1, audit_finding: :inaccurate, policy: :flexible, premium?: false),
    RawData.new(1, audit_finding: :no_issue, policy: :flexible, premium?: true),
    RawData.new(2, audit_finding: :no_issue, policy: :immediate, premium?: false)
  ]

  @listing_7_2 [
    RawData.new(7, audit_finding: :no_issue),
    RawData.new(7, premium?: false),
    RawData.new(7, policy: :flexible),
    RawData.new(8, audit_finding: :no_issue, policy: :immediate, premium?: false)
  ]

  test "list 7.1" do
    Etl.clean_duplicates(@listing_7_1) |> dbg
  end

  test "list 7.2" do
    Etl.clean_duplicates(@listing_7_2) |> dbg
  end
end
