defmodule Invoicing.Records.Rule do
  use Ecto.Schema

  @type t :: %__MODULE__{
          id: integer() | nil,
          minimum_fee_threshold: Decimal.t() | nil,
          maximum_fee_threshold: Decimal.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "rules" do
    field :minimum_fee_threshold, :decimal
    field :maximum_fee_threshold, :decimal

    timestamps()
  end
end
