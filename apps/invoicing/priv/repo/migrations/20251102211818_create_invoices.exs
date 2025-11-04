defmodule Invoicing.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:invoices) do
      add :status, :string
      add :invoice_date, :date
      add :due_date, :date
      add :invoice_type, :string
      add :customer_id, references(:customers, on_delete: :nothing)

      timestamps()
    end

    create index(:invoices, [:customer_id])
  end
end
