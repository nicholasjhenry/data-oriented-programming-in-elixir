defmodule Invoicing.Repo.Migrations.CreateLineItems do
  use Ecto.Migration

  def change do
    create table(:line_items) do
      add :description, :string
      add :charges, :decimal
      add :currency, :string
      add :invoice_id, references(:invoices, on_delete: :nothing)

      timestamps()
    end

    create index(:line_items, [:invoice_id])
  end
end
