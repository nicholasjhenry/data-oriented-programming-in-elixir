defmodule Invoicing.Records.AuditInfo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_info" do
    field :cannot_bill_reason, :string
    field :invoice_id, :id
    field :included_in_fee, :id

    timestamps()
  end

  @doc false
  def changeset(audit_info, attrs) do
    audit_info
    |> cast(attrs, [:cannot_bill_reason])
    |> validate_required([:cannot_bill_reason])
  end
end
