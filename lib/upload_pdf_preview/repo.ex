defmodule UploadPdfPreview.Repo do
  use Ecto.Repo,
    otp_app: :upload_pdf_preview,
    adapter: Ecto.Adapters.Postgres
end
