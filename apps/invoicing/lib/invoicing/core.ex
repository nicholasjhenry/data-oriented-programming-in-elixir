defmodule Invoicing.Core do
  alias Invoicing.Types.EnrichedCustomer
  alias Invoicing.Types.LateFee
  alias Invoicing.Types.Lifecycle
  alias Invoicing.Types.PastDue
  alias Invoicing.Types.Reason
  alias Invoicing.Types.ReviewedFee

  alias Invoicing.Types.Percentage
  alias Invoicing.Types.USD

  alias Invoicing.Records

  @spec build_draft(Date.t(), EnrichedCustomer.t(), list(PastDue.t())) ::
          LateFee.t(Lifecycle.Draft.t())
  def build_draft(today, customer, invoices) do
    %LateFee{
      state: %Lifecycle.Draft{},
      customer: customer,
      total: compute_fee(invoices, customer.fee_percentage),
      invoice_date: today,
      due_date: due_date(today, customer.terms),
      included_in_fee: invoices
    }
  end

  @spec compute_fee(list(PastDue.t()), Percentage.t()) :: USD.t()
  def compute_fee(past_due, fee_percentage) do
    past_due
    |> compute_total()
    |> USD.multiply(Percentage.to_decimal(fee_percentage))
  end

  @spec compute_total(list(PastDue.t())) :: USD.t()
  def compute_total(invoices) do
    invoices
    |> Enum.flat_map(& &1.invoice.line_items)
    |> Enum.map(&unsafe_get_charges_in_usd/1)
    |> Enum.reduce(USD.zero(), &USD.add/2)
  end

  @spec unsafe_get_charges_in_usd(Records.LineItem.t()) :: USD.t()
  def unsafe_get_charges_in_usd(line_item) do
    if line_item.currency != "USD" do
      raise "Non-USD currency found in line items"
    else
      %USD{value: line_item.charges}
    end
  end

  @type payment_terms :: :net_30 | :net_60 | :due_on_receipt | :end_of_month

  @spec due_date(Date.t(), payment_terms()) :: Date.t()
  def due_date(today, terms) do
    case terms do
      :net_30 -> Date.add(today, 30)
      :net_60 -> Date.add(today, 60)
      :due_on_receipt -> today
      :end_of_month -> Date.end_of_month(today)
    end
  end

  @spec assess_draft(any(), LateFee.t(Lifecycle.Draft.t())) :: ReviewedFee.t()
  def assess_draft(rules, draft) do
    case assess_total(rules, draft.total) do
      :within_range ->
        %ReviewedFee.Billable{late_fee: draft}

      :below_minimum ->
        %ReviewedFee.NotBillable{late_fee: draft, reason: %Reason{value: "Below threshold"}}

      :above_maximum ->
        if is_nil(draft.customer.approval) do
          %ReviewedFee.NeedsApproval{late_fee: draft}
        else
          case draft.customer.approval.status do
            :approved ->
              %ReviewedFee.Billable{late_fee: draft}

            :pending ->
              %ReviewedFee.NotBillable{
                late_fee: draft,
                reason: %Reason{value: "Approval pending"}
              }

            :denied ->
              %ReviewedFee.NotBillable{
                late_fee: draft,
                reason: %Reason{value: "exempt from large fees"}
              }
          end
        end
    end
  end

  @type assessment :: :below_minimum | :above_maximum | :within_range

  @spec assess_total(any(), USD.t()) :: assessment()
  def assess_total(rules, total) do
    cond do
      Decimal.compare(total.value, rules.get_minimum_fee_threshold()) == :lt -> :below_minimum
      Decimal.compare(total.value, rules.get_maximum_fee_threshold()) == :gt -> :above_maximum
      true -> :within_range
    end
  end

  @spec collect_past_due(EnrichedCustomer.t(), Date.t(), list(Records.Invoice.t())) ::
          list(PastDue.t())
  def collect_past_due(customer, today, invoices) do
    invoices
    |> Enum.filter(&past_due?(&1, customer.rating, today))
    |> Enum.map(&%PastDue{invoice: &1})
  end

  @type customer_rating :: :good | :acceptable | :poor

  @spec past_due?(Records.Invoice.t(), customer_rating(), Date.t()) :: boolean()
  def past_due?(invoice, rating, today) do
    invoice.invoice_type == :standard and
      invoice.status == :open and
      Date.compare(today, grace_period(rating).(invoice.due_date)) == :gt
  end

  @spec grace_period(customer_rating()) :: (Date.t() -> Date.t())
  def grace_period(rating) do
    case rating do
      :good -> fn date -> Date.add(date, 60) end
      :acceptable -> fn date -> Date.add(date, 30) end
      :poor -> &Date.end_of_month/1
    end
  end
end
