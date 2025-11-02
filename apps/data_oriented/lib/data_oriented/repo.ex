defmodule DataOriented.Repo do
  use Ecto.Repo,
    otp_app: :data_oriented,
    adapter: Ecto.Adapters.Postgres
end
