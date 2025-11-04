defmodule Invoicing.Types do
  use TypedStruct

  defmodule USD do
    use TypedStruct

    typedstruct enforce: true do
      field :value, Decimal.t()
    end

    @spec multiple(t(), Decimal.t()) :: t()
    def multiple(usd, amount) do
      %__MODULE__{value: Decimal.mult(usd.value, Decimal.new(amount))}
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
      field :numerator, non_negative_integer()
      field :denominator, non_negative_integer()
    end

    @spec new(non_negative_integer(), non_negative_integer()) :: t()
    def new(numerator, denominator) when denominator > 0 do
      %__MODULE__{numerator: numerator, denominator: denominator}
    end

    @spec to_decimal(t()) :: Decimal.t()
    def to_decimal(percentage) do
      Decimal.div(Decimal.new(percentage.numerator), Decimal.new(percentage.denominator))
    end
  end




  defmodule PastDueInvoice do
    use TypedStruct

    alias Invoicing.Invoice

    typedstruct enforce: true do
      field :value, Invoice.t()
    end
  end

  defmodule Lifecycle do
    defmodule Draft do
      use TypedStruct

      typedstruct enforce: true do
      end
    end

    defmodule Billed do
      use TypedStruct

      typedstruct enforce: true do
        field :invoice_id, String.t()
      end
    end

    defmodule Rejected do
      use TypedStruct

      typedstruct enforce: true do
        field :reason, String.t()
      end
    end

    defmodule InReview do
      use TypedStruct

      typedstruct enforce: true do
        field :approval_id, String.t()
      end
    end

    @type t ::
            Draft.t()
            | Billed.t()
            | Rejected.t()
            | InReview.t()
  end

  defmodule Latefee do
    use TypedStruct

    alias Invoicing.Invoice
    alias Invoicing.Types.Lifecycle

    @enforce_keys [:customer_id, :usd, :state, :invoice_date, :due_date, :included_in_fee]
    defstruct [:customer_id, :usd, :state, :invoice_date, :due_date, :included_in_fee]

    @type t(state) :: %__MODULE__{
            customer_id: String.t(),
            usd: Decimal.t(),
            state: state,
            invoice_date: NaiveDateTime.t(),
            due_date: NaiveDateTime.t(),
            included_in_fee: list(Invoice.t())
          }

    @type t :: t(Lifecycle.t())
  end

  defmodule ReviewedFee do
    defmodule Billable do
      use TypedStruct

      alias Invoicing.Types.Latefee
      alias Invoicing.Types.Lifecycle.Draft

      typedstruct enforce: true do
        field :late_fee, Latefee.t(Draft.t())
      end
    end

    defmodule NeedsReview do
      use TypedStruct

      alias Invoicing.Types.Latefee
      alias Invoicing.Types.Lifecycle.Draft

      typedstruct enforce: true do
        field :late_fee, Latefee.t(Draft.t())
      end
    end

    defmodule NotBillable do
      use TypedStruct

      alias Invoicing.Types.Latefee
      alias Invoicing.Types.Lifecycle.Draft

      typedstruct enforce: true do
        field :late_fee, Latefee.t(Draft.t())
        field :reason, String.t()
      end
    end

    @type t ::
            Billable.t()
            | NeedsReview.t()
            | NotBillable.t()
  end
end
