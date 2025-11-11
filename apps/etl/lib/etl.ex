defmodule Etl do
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

  @type customer_impact :: :harms | :favours

  def policy_impact(:grace_period), do: :favours
  def policy_impact(:flexible), do: :favours
  def policy_impact(_stage), do: :harms

  def finding_impact(:no_issue), do: :favours
  def finding_impact(:inaccurate), do: :favours
  def finding_impact(_stage), do: :harms

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

  def add_policies(x, y) do
    max_by(&compare_customer_impact/2).(policy_impact(x), policy_impact(y))
  end

  def add_findings(x, y) do
    max_by(&compare_customer_impact/2).(finding_impact(x), finding_impact(y))
  end

  def max_by(comparator) do
    fn x, y -> if comparator.(x, y) >= 0, do: x, else: y end
  end

  def add_statuses(x, y) do
    x || y
  end

  def clean_duplicates(data) do
    data
    |> to_map(& &1.id, &Map.merge/2)
    |> Map.values()
  end

  defp to_map(data, classifier, binary_op) do
    data
    |> Enum.map(fn row -> %{classifier.(row) => row} end)
    |> Enum.reduce(Map.new(), binary_op)
  end
end
