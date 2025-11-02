defmodule Invoicing.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :address, :string
      add :approval_id, :string

      timestamps()
    end
  end
end
