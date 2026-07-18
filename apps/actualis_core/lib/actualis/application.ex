defmodule Actualis.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Actualis.Repo,
      {DNSCluster, query: Application.get_env(:actualis_core, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Actualis.PubSub}
      # Start a worker by calling: Actualis.Worker.start_link(arg)
      # {Actualis.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Actualis.Supervisor)
  end
end
