defmodule Astral.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        AstralWeb.Telemetry,
        Astral.Repo,
        {DNSCluster, query: Application.get_env(:astral, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Astral.PubSub},
        # Start the Finch HTTP client for sending emails
        {Finch, name: Astral.Finch},
        # Start a worker by calling: Astral.Worker.start_link(arg)
        # {Astral.Worker, arg},
        # Start to serve requests, typically the last entry
        AstralWeb.Endpoint
      ]
      |> start_nostrum(Application.get_env(:astral, :nostrum, []))

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Astral.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_nostrum(children, _config), do: children ++ [AstralDiscord.Consumer]

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AstralWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
