defmodule Invoicing.Infrastructure.Services do
  use TypedStruct

  defmodule RatingsAPI do
    @moduledoc """
    API for customer ratings.
    """

    @type customer_rating :: :good | :acceptable | :poor
    @type customer_id :: String.t()

    @spec get_rating(customer_id()) :: customer_rating()
    def get_rating(customer_id) do
      apply(Fake, :get_rating, [customer_id])
    end
  end

  defmodule ContractsAPI do
    @moduledoc """
    API for retrieving contract payment terms.
    """

    @type payment_terms :: :net_30 | :net_60 | :end_of_month | :due_on_receipt
    @type customer_id :: String.t()

    @spec get_payment_terms(customer_id()) :: payment_terms()
    def get_payment_terms(customer_id) do
      apply(Fake, :get_payment_terms, [customer_id])
    end
  end

  defmodule ApprovalsAPI do
    @moduledoc """
    API for managing approvals.
    """

    @type approval_status :: :pending | :approved | :denied
    @type approval_id :: String.t()

    defmodule Approval do
      use TypedStruct

      @moduledoc """
      Represents an approval with its current status.
      """

      typedstruct enforce: true do
        field :id, String.t()
        field :status, ApprovalsAPI.approval_status()
      end
    end

    defmodule CreateApprovalRequest do
      use TypedStruct

      @moduledoc """
      Request structure for creating a new approval.
      """

      typedstruct do
        # Add fields as needed
      end
    end

    @spec create_approval(CreateApprovalRequest.t()) :: Approval.t()
    def create_approval(request) do
      apply(Fake, :create_approval, [request])
    end

    @spec get_approval(approval_id()) :: {:ok, Approval.t()} | {:error, :not_found}
    def get_approval(approval_id) do
      apply(Fake, :get_approval, [approval_id])
    end
  end

  defmodule BillingAPI do
    @moduledoc """
    API for submitting invoices to billing system.
    """

    @type status :: :accepted | :rejected
    @type invoice_id :: String.t()

    defmodule SubmitInvoiceRequest do
      use TypedStruct

      @moduledoc """
      Request structure for submitting an invoice.
      """

      typedstruct do
        # Add fields as needed
      end
    end

    defmodule BillingResponse do
      use TypedStruct

      @moduledoc """
      Response from billing system after invoice submission.
      """

      typedstruct enforce: true do
        field :status, BillingAPI.status()
        field :invoice_id, String.t() | nil
        field :error, String.t() | nil
      end
    end

    @spec submit(SubmitInvoiceRequest.t()) :: BillingResponse.t()
    def submit(request) do
      apply(Fake, :submit, [request])
    end
  end
end
