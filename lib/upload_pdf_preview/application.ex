defmodule UploadPdfPreview.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      UploadPdfPreviewWeb.Telemetry,
      UploadPdfPreview.Repo,
      {DNSCluster, query: Application.get_env(:upload_pdf_preview, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: UploadPdfPreview.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: UploadPdfPreview.Finch},
      # Start a worker by calling: UploadPdfPreview.Worker.start_link(arg)
      # {UploadPdfPreview.Worker, arg},
      # Start to serve requests, typically the last entry
      UploadPdfPreviewWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: UploadPdfPreview.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    UploadPdfPreviewWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
