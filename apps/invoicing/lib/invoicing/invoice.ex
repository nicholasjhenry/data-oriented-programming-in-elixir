defmodule Invoicing.Invoice do
  use Ecto.Schema
  import Ecto.Changeset

  schema "invoices" do
    field :status, Ecto.Enum, values: [:open, :close]
    field :invoice_date, :naive_datetime
    field :due_date, :naive_datetime
    field :invoice_type, Ecto.Enum, values: [:latefee, :standard]
    field :customer_id, :id

    timestamps()
  end

  @doc false
  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [:status, :invoice_date, :due_date, :invoice_type])
    |> validate_required([:status, :invoice_date, :due_date, :invoice_type])
  end
end
