defmodule Invoicing.Service do
  import Ecto.Query
  use TypedStruct

  alias Invoicing.Repo
  alias Invoicing.Records
  alias Invoicing.Core

  alias Invoicing.Types.EnrichedCustomer
  alias Invoicing.Types.LateFee
  alias Invoicing.Types.Lifecycle
  alias Invoicing.Types.Reason
  alias Invoicing.Types.ReviewedFee

  alias Invoicing.Types.InvoiceId

  alias Invoicing.Infrastructure.Services

  typedstruct module: InvoicingData, enforce_all: true do
    field :current_date, Date.t()
    field :customer, EnrichedCustomer.t()
    field :invoices, list(Records.Invoice.t())
    field :rules, list(Records.Rule.t())
  end

  def process_late_fees() do
    # ---- NON-DETERMINISTIC SHELL --------
    Repo.transaction(fn ->
      load_invoicing_data()
      # ---- DETERMINISTIC CORE --------
      |> Stream.each(fn data ->
        today = Date.utc_today()
        customer = data.customer
        past_due = Core.collect_past_due(customer, today, data.invoices)
        draft = Core.build_draft(today, customer, past_due)
        reviewed = Core.assess_draft(data.rules, draft)

        # ---- NON-DETERMINISTIC SHELL --------
        late_fee =
          case reviewed do
            %ReviewedFee.Billable{} = billable ->
              submit_bill(billable)

            %ReviewedFee.NeedsApproval{} = needs_approval ->
              start_approval(needs_approval)

            %ReviewedFee.NotBillable{} = not_billable ->
              LateFee.mark_not_billed(not_billable.late_fee, not_billable.reason)
          end

        save_late_fee(late_fee)
      end)
      |> Stream.run()
    end)
  end

  @spec submit_bill(ReviewedFee.Billable.t()) :: LateFee.t()
  def submit_bill(billable) do
    response = Services.BillingAPI.submit(%Services.BillingAPI.SubmitInvoiceRequest{})

    case response.status do
      :accepted ->
        LateFee.mark_billed(billable.late_fee, %InvoiceId{value: response.invoice_id})

      :rejected ->
        LateFee.mark_not_billed(billable.late_fee, %Reason{value: response.error})
    end
  end

  @spec start_approval(ReviewedFee.NeedsApproval.t()) :: LateFee.t(Lifecycle.UnderReview.t())
  def start_approval(needs_approval) do
    approval =
      Services.ApprovalsAPI.create_approval(%Services.ApprovalsAPI.CreateApprovalRequest{})

    LateFee.mark_as_being_reviewed(needs_approval.late_fee, approval.id)
  end

  @spec save_late_fee(LateFee.t()) :: {:ok, Records.Customer.t()} | :ok
  defp save_late_fee(late_fee) do
    late_fee
    |> to_invoice()
    |> Repo.insert()

    case late_fee.state do
      %Lifecycle.UnderReview{} ->
        late_fee
        |> to_customer()
        |> Repo.insert()

      %Lifecycle.Billed{} ->
        :ok

      %Lifecycle.Rejected{} ->
        :ok
    end
  end

  @spec load_invoicing_data() :: Enumerable.t(InvoicingData.t())
  defp load_invoicing_data do
    customers_query =
      from c in Records.Customer,
        order_by: c.id

    rules = Repo.all(Record.Rule)

    Repo.stream(customers_query, max_rows: 100)
    |> Stream.map(fn customer ->
      invoices =
        from(i in Records.Invoice,
          where: i.customer_id == ^customer.id,
          preload: [:line_items]
        )
        |> Repo.all()

      %InvoicingData{
        current_date: Date.utc_today(),
        customer: customer,
        invoices: invoices,
        rules: rules
      }
    end)
  end

  @spec to_invoice(LateFee.t()) :: Records.Invoice.t()
  defp to_invoice(late_fee) do
    {invoice_id, cannot_bill_reason} =
      case late_fee.state do
        %Lifecycle.Billed{} = billed ->
          {billed.id.value, nil}

        %Lifecycle.Rejected{} = rejected ->
          {nil, rejected.why.value}

        %Lifecycle.UnderReview{} ->
          {nil, "Under review"}
      end

    %Records.Invoice{
      id: invoice_id,
      customer_id: late_fee.customer.id.value,
      line_items: [
        %Records.LineItem{
          description: "Late Fee",
          charges: late_fee.total.value,
          currency: late_fee.currency
        }
      ],
      status: :open,
      invoice_date: late_fee.invoice_date,
      due_date: late_fee.due_date,
      invoice_type: :latefee,
      audit_info: %Records.AuditInfo{
        included_in_fee: late_fee.included_in_fee,
        cannot_bill_reason: cannot_bill_reason
      }
    }
  end

  @spec to_customer(LateFee.t(Lifecycle.UnderReview.t())) :: Records.Customer.t()
  defp to_customer(late_fee) do
    %Records.Customer{
      id: String.to_integer(late_fee.customer.id.value),
      address: late_fee.customer.address,
      approval_id: late_fee.state.id
    }
  end
end
