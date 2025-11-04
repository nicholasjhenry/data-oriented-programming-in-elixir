defmodule Invoicing.Records.LineItem do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          description: String.t() | nil,
          charges: Decimal.t() | nil,
          currency: String.t() | nil,
          invoice_id: integer() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "line_items" do
    field :description, :string
    field :charges, :decimal
    field :currency, :string
    field :invoice_id, :integer

    timestamps()
  end

  @doc false
  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:description, :charges, :currency])
    |> validate_required([:description, :charges, :currency])
  end
end
