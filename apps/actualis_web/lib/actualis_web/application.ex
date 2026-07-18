defmodule ActualisWeb.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ActualisWeb.Telemetry,
      # Start a worker by calling: ActualisWeb.Worker.start_link(arg)
      # {ActualisWeb.Worker, arg},
      # Start to serve requests, typically the last entry
      ActualisWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ActualisWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ActualisWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
