defmodule Etl do
  # TODO: Wait for the chapter to be revised.
  alias Funx.Monad.Maybe

  @type policy :: :grace_period | :flexibile | :immediate | :strict | :manual_review
  @type audit_finding :: :billing_error | :out_of_compliance | :inaccurate | :no_issue

  defmodule RawData do
    use TypedStruct

    typedstruct enforce: true do
      field(:id, String.t())
      field(:policy, Maybe.t(String.t()))
      field(:audit_finding, Maybe.t(String.t()))
      field(:premium?, Maybe.t(boolean()))
    end

    def new(id, attrs) do
      attrs = Map.new(attrs)

      %__MODULE__{
        id: id,
        policy: Map.get(attrs, :policy) |> Maybe.from_nil(),
        audit_finding: Map.get(attrs, :audit_finding) |> Maybe.from_nil(),
        premium?: Map.get(attrs, :premium?) |> Maybe.from_nil()
      }
    end
  end

  @type customer_impact :: :harms | :favors

  def policy_impact(:grace_period), do: :favors
  def policy_impact(:flexible), do: :favors
  def policy_impact(:immediate), do: :harms
  def policy_impact(nil), do: :favors

  def finding_impact(:no_issue), do: :favors
  def finding_impact(:inaccurate), do: :favors
  def finding_impact(:out_of_compliance), do: :harms
  def finding_impact(nil), do: :harms

  def clean_duplicates(data) do
    data
    |> to_map(& &1.id, &add_rows/2)
    |> Map.values()
  end

  defp to_map(data, classifier, binary_op) do
    data
    |> Enum.map(fn row -> %{classifier.(row) => row} end)
    |> Enum.reduce(Map.new(), binary_op)
  end

  defp add_rows(row_map, acc_map) when map_size(acc_map) == 0 do
    row_map
  end

  defp add_rows(row_map, acc_map) do
    [{id, row}] = Map.to_list(row_map)
    merged_row = merge(row, acc_map[id])
    Map.put(acc_map, id, merged_row)
  end

  def merge(%{id: id} = lhs, %{id: id} = rhs) do
    RawData.new(
      id,
      policy: add_policies(lhs.policy, rhs.policy),
      audit_finding: add_findings(lhs.audit_finding, rhs.audit_finding),
      premium?: add_statuses(lhs.premium?, rhs.premium?)
    )
  end

  def compare_customer_impact(:favors, :favors), do: 0
  def compare_customer_impact(:favors, :harms), do: 1
  def compare_customer_impact(:harms, :favors), do: -1
  def compare_customer_impact(:harms, :harms), do: 0

  def with_maybe(fun, args) do
    Enum.map(args, fn maybe ->
      maybe
      |> Maybe.to_nil()
      |> fun.()
    end)
  end

  def add_policies(x, y) do
    apply(max_by(&compare_customer_impact/2), with_maybe(&policy_impact/1, [x, y]))
    # TODO: compare by policy name
  end

  def add_findings(x, y) do
    apply(max_by(&compare_customer_impact/2), with_maybe(&finding_impact/1, [x, y]))
    # TODO: compare by finding name
  end

  def max_by(comparator) do
    fn x, y -> if comparator.(x, y) >= 0, do: x, else: y end
  end

  def add_statuses(x, y) do
    x || y
  end
end
