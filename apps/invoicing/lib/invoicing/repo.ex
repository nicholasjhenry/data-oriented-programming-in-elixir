defmodule Invoicing.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :invoicing,
    adapter: Ecto.Adapters.Postgres
end
