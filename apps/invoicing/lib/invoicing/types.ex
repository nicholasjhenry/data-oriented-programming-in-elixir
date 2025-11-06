defmodule Invoicing.Types do
  use TypedStruct

  alias Invoicing.Records
  alias Invoicing.Infrastructure.Services

  defmodule USD do
    use TypedStruct

    typedstruct enforce: true do
      field :value, Decimal.t()
    end

    @spec multiply(t(), Decimal.t()) :: t()
    def multiply(usd, amount) do
      %__MODULE__{value: Decimal.mult(usd.value, amount)}
    end

    @spec zero() :: t()
    def zero do
      %__MODULE__{value: Decimal.new(0)}
    end

    @spec add(t(), t()) :: t()
    def add(a, b) do
      %__MODULE__{value: Decimal.add(a.value, b.value)}
    end
  end

  defmodule Percentage do
    use TypedStruct

    typedstruct enforce: true do
      field :numerator, non_neg_integer()
      field :denominator, non_neg_integer()
    end

    @spec new(non_neg_integer(), non_neg_integer()) :: t()
    def new(numerator, denominator) when denominator > 0 and numerator <= denominator do
      %__MODULE__{numerator: numerator, denominator: denominator}
    end

    @spec to_decimal(t()) :: Decimal.t()
    def to_decimal(percentage) do
      Decimal.div(Decimal.new(percentage.numerator), Decimal.new(percentage.denominator))
    end
  end

  typedstruct module: CustomerId, enforce: true do
    field :value, String.t()
  end

  typedstruct module: PastDue, enforce: true do
    field :invoice, Records.Invoice.t()
  end

  typedstruct module: InvoiceId, enforce: true do
    field :value, String.t()
  end

  typedstruct module: Reason, enforce: true do
    field :value, String.t()
  end

  defmodule Lifecycle do
    use TypedStruct

    typedstruct module: Draft, enforce: true do
    end

    typedstruct module: UnderReview, enforce: true do
      field :id, String.t()
    end

    typedstruct module: Billed, enforce: true do
      field :id, InvoiceId.t()
    end

    typedstruct module: Rejected, enforce: true do
      field :why, Reason.t()
    end

    @type t ::
            Draft.t()
            | UnderReview.t()
            | Billed.t()
            | Rejected.t()
  end

  defmodule LateFee do
    use TypedStruct

    alias Invoicing.Types.EnrichedCustomer
    alias Invoicing.Types.InvoiceId
    alias Invoicing.Types.Lifecycle
    alias Invoicing.Types.Reason
    alias Invoicing.Types.USD
    alias Invoicing.Types.PastDue

    @enforce_keys [:customer, :total, :state, :invoice_date, :due_date, :included_in_fee]
    defstruct [:customer, :total, :state, :invoice_date, :due_date, :included_in_fee]

    @type t(state) :: %__MODULE__{
            state: state,
            customer: EnrichedCustomer.t(),
            total: USD.t(),
            invoice_date: Date.t(),
            due_date: Date.t(),
            included_in_fee: list(PastDue.t())
          }

    @type t :: t(Lifecycle.t())

    @spec mark_billed(t(), InvoiceId.t()) :: t(Lifecycle.Billed.t())
    def mark_billed(late_fee, id) do
      %{late_fee | state: %Lifecycle.Billed{id: id}}
    end

    @spec mark_not_billed(t(), Reason.t()) :: t(Lifecycle.Rejected.t())
    def mark_not_billed(late_fee, reason) do
      %{late_fee | state: %Lifecycle.Rejected{why: reason}}
    end

    @spec mark_as_being_reviewed(t(), String.t()) :: t(Lifecycle.UnderReview.t())
    def mark_as_being_reviewed(late_fee, approval_id) do
      %{late_fee | state: %Lifecycle.UnderReview{id: approval_id}}
    end

    @spec in_state(t(), Lifecycle.t()) :: t()
    def in_state(late_fee, evidence) do
      %{late_fee | state: evidence}
    end
  end

  defmodule ReviewedFee do
    use TypedStruct

    alias Invoicing.Types.LateFee
    alias Invoicing.Types.Lifecycle.Draft
    alias Invoicing.Types.Reason

    typedstruct module: Billable, enforce: true do
      field :late_fee, LateFee.t(Draft.t())
    end

    typedstruct module: NeedsApproval, enforce: true do
      field :late_fee, LateFee.t(Draft.t())
    end

    typedstruct module: NotBillable, enforce: true do
      field :late_fee, LateFee.t(Draft.t())
      field :reason, Reason.t()
    end

    @type t ::
            Billable.t()
            | NeedsApproval.t()
            | NotBillable.t()
  end

  defmodule EnrichedCustomer do
    use TypedStruct

    alias Invoicing.Types.CustomerId

    typedstruct enforce: true do
      field :id, CustomerId.t()
      field :address, String.t()
      field :fee_percentage, Percentage.t()
      field :terms, Services.ContractsAPI.payment_terms()
      field :rating, Services.RatingsAPI.customer_rating()
      field :approval, Services.ApprovalsAPI.approval_status() | nil
    end
  end
end
