defmodule Invoicing.Repo.Migrations.CreateAuditInfo do
  use Ecto.Migration

  def change do
    create table(:audit_info) do
      add :cannot_bill_reason, :string
      add :invoice_id, references(:invoices, on_delete: :nothing)
      add :included_in_fee, references(:invoices, on_delete: :nothing)

      timestamps()
    end

    create index(:audit_info, [:invoice_id])
    create index(:audit_info, [:included_in_fee])
  end
end
