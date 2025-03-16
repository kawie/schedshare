defmodule Schedshare.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SchedshareWeb.Telemetry,
      Schedshare.Repo,
      {Ecto.Migrator,
        repos: Application.fetch_env!(:schedshare, :ecto_repos),
        skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:schedshare, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Schedshare.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Schedshare.Finch},
      # Start a worker by calling: Schedshare.Worker.start_link(arg)
      # {Schedshare.Worker, arg},
      # Start to serve requests, typically the last entry
      SchedshareWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Schedshare.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SchedshareWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # Always run migrations on startup for SQLite
    false
  end
end
