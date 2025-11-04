defmodule Invoicing.Records.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          address: String.t() | nil,
          approval_id: String.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "customers" do
    field :address, :string
    field :approval_id, :string

    timestamps()
  end

  @doc false
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:address, :approval_id])
    |> validate_required([:address, :approval_id])
  end
end
