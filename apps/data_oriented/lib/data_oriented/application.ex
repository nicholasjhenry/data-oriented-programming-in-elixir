defmodule DataOriented.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DataOriented.Repo,
      {DNSCluster, query: Application.get_env(:data_oriented, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DataOriented.PubSub}
      # Start a worker by calling: DataOriented.Worker.start_link(arg)
      # {DataOriented.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: DataOriented.Supervisor)
  end
end
