defmodule Invoicing.Records.Invoice do
  use Ecto.Schema
  import Ecto.Changeset

  alias Invoicing.Records

  @type t :: %__MODULE__{
          id: String.t() | nil,
          status: :open | :close,
          invoice_date: Date.t() | nil,
          due_date: Date.t() | nil,
          invoice_type: :latefee | :standard,
          customer_id: String.t() | nil,
          line_items: list(Records.LineItem.t()) | Ecto.Association.NotLoaded.t(),
          audit_info: Records.AuditInfo.t() | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "invoices" do
    field :status, Ecto.Enum, values: [:open, :close]
    field :invoice_date, :date
    field :due_date, :date
    field :invoice_type, Ecto.Enum, values: [:latefee, :standard]
    field :customer_id, :id

    has_many :line_items, Records.LineItem
    has_one :audit_info, Records.AuditInfo

    timestamps()
  end

  @doc false
  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [:status, :invoice_date, :due_date, :invoice_type])
    |> validate_required([:status, :invoice_date, :due_date, :invoice_type])
  end
end
