defmodule Invoicing.LineItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "line_items" do
    field :description, :string
    field :charges, :decimal
    field :currency, :string
    field :invoice_id, :id

    timestamps()
  end

  @doc false
  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:description, :charges, :currency])
    |> validate_required([:description, :charges, :currency])
  end
end
