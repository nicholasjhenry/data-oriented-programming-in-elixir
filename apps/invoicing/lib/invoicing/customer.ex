defmodule Invoicing.Customer do
  use Ecto.Schema
  import Ecto.Changeset

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
