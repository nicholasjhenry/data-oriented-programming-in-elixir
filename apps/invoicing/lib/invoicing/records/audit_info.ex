defmodule Invoicing.Records.AuditInfo do
  use Ecto.Schema
  import Ecto.Changeset

  alias Invoicing.Types.PastDue

  @type t :: %__MODULE__{
          id: integer() | nil,
          invoice_id: integer() | nil,
          included_in_fee: list(PastDue.t()) | nil,
          cannot_bill_reason: String.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "audit_info" do
    field :invoice_id, :id
    field :included_in_fee, :id
    field :cannot_bill_reason, :string

    timestamps()
  end

  @doc false
  def changeset(audit_info, attrs) do
    audit_info
    |> cast(attrs, [:cannot_bill_reason])
    |> validate_required([:cannot_bill_reason])
  end
end
