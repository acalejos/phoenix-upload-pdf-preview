defmodule UploadPdfPreviewWeb.DemoLive.Index do
  use UploadPdfPreviewWeb, :live_view

  @impl true
  def mount(_session, _params, socket) do
    socket =
      socket
      |> assign(:uploaded_files, [])
      |> allow_upload(
        :demo,
        accept: ~w(.pdf .jpg .jpeg .png .tif .tiff),
        max_entries: 5
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <form id="upload-form" phx-submit="submit_upload" phx-change="validate_upload">
        <h2 class="text-base font-semibold leading-7 text-gray-900">Add Up to 5 Files</h2>
        <p class="mt-1 text-sm leading-6 text-gray-500">
          Accepts PDF, JPEG, PNG, and TIFF files.
        </p>

        <div class="px-4 py-6 border-t border-gray-200">
          <div
            phx-drop-target={@uploads.demo.ref}
            class="relative block w-full rounded-lg border-2 border-dashed border-gray-300 p-12 text-center hover:border-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="mx-auto h-12 w-12 text-gray-400"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M12 16.5V9.75m0 0l3 3m-3-3l-3 3M6.75 19.5a4.5 4.5 0 01-1.41-8.775 5.25 5.25 0 0110.233-2.33 3 3 0 013.758 3.848A3.752 3.752 0 0118 19.5H6.75z"
              />
            </svg>
            <div class="mt-4 flex text-sm leading-6 text-gray-600 justify-center ">
              <label
                for={@uploads.demo.ref}
                class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none hover:text-indigo-500"
              >
                <span>Upload a file</span>
                <input
                  id={@uploads.demo.ref}
                  type="file"
                  name={@uploads.demo.name}
                  accept={@uploads.demo.accept}
                  data-phx-hook="LiveFileUpload"
                  data-phx-update="ignore"
                  data-phx-upload-ref={@uploads.demo.ref}
                  data-phx-active-refs={join_refs(for(entry <- @uploads.demo.entries, do: entry.ref))}
                  data-phx-done-refs={
                    join_refs(for(entry <- @uploads.demo.entries, entry.done?, do: entry.ref))
                  }
                  data-phx-preflighted-refs={
                    join_refs(for(entry <- @uploads.demo.entries, entry.preflighted?, do: entry.ref))
                  }
                  data-phx-auto-upload={@uploads.demo.auto_upload?}
                  multiple={@uploads.demo.max_entries > 1}
                  class="sr-only"
                />
              </label>
              <p class="pl-1">or drag and drop</p>
            </div>
          </div>
        </div>

        <ul
          id="preview-grid"
          phx-hook="GatherPreviews"
          role="list"
          class="grid grid-cols-2 gap-x-4 gap-y-8 sm:grid-cols-1 sm:gap-x-6 lg:grid-cols-3 xl:gap-x-8"
        >
          <li :for={entry <- @uploads.demo.entries} class="relative">
            <div class="group aspect-h-7 aspect-w-10 block w-full overflow-hidden rounded-lg bg-gray-100 focus-within:ring-2 focus-within:ring-indigo-500 focus-within:ring-offset-2 focus-within:ring-offset-gray-100">
              <img
                id={"phx-preview-#{entry.ref}"}
                data-phx-upload-ref={entry.upload_ref}
                data-phx-entry-ref={entry.ref}
                data-phx-hook={
                  if entry.client_type == "application/pdf",
                    do: "LivePdfPreview",
                    else: "Phoenix.LiveImgPreview"
                }
                data-phx-update="ignore"
              />
              <button
                type="button"
                phx-click="cancel_upload"
                phx-value-ref={entry.ref}
                aria-label="cancel"
                class="absolute -right-2 -top-2"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 20 20"
                  fill="#3f3f46"
                  class="w-5 h-5 "
                >
                  <path
                    fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z"
                    clip-rule="evenodd"
                  />
                </svg>
              </button>
            </div>
            <p class="pointer-events-none mt-2 block truncate text-sm font-medium text-gray-900">
              <%= entry.client_name %>
            </p>
            <p class="pointer-events-none block text-sm font-medium text-gray-500">
              <%= to_megabytes_or_kilobytes(entry.client_size) %>
            </p>
            <div :if={upload_errors(@uploads.demo, entry)} class="rounded-md bg-red-50">
              <div class="flex">
                <div class="ml-2">
                  <div class="text-sm text-red-700">
                    <ul role="list" class="exclamation-triangle space-y-1 pl-3">
                      <li :for={err <- upload_errors(@uploads.demo, entry)}>
                        <%= error_to_string(err) %>
                      </li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          </li>
        </ul>
        <button
          phx-click={JS.dispatch("submit", to: "#upload-form")}
          disabled={Enum.any?(@uploads.demo.entries, &(not &1.valid?))}
          class={[
            "right-10 mr-5 rounded-md bg-gray-900 px-3 py-4",
            "text-sm font-semibold text-white shadow-sm hover:bg-gray-700",
            Enum.any?(@uploads.demo.entries, &(not &1.valid?)) && "cursor-not-allowed"
          ]}
        >
          Upload
        </button>
      </form>
    </div>
    """
  end

  @impl true
  def handle_event("submit_upload", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :demo, fn %{path: _path}, entry ->
        case entry.client_type do
          "application/pdf" ->
            # Handle PDFs
            IO.puts("PDF")

          _ ->
            # Handle images
            IO.puts("Image")
        end
      end)

    socket =
      socket
      |> update(:uploaded_files, &(&1 ++ uploaded_files))
      |> push_event("gatherPreviews", %{})

    {:noreply, socket}
  end

  def handle_event("update_preview_srcs", %{"srcs" => srcs}, socket) do
    uploaded_files =
      socket.assigns.uploaded_files
      |> Enum.map(fn entry ->
        if Map.has_key?(srcs, entry.ref) do
          entry
          |> Map.put(:preview_src, Map.fetch!(srcs, entry.ref))
        else
          entry
        end
      end)

    socket =
      socket
      |> assign(:uploaded_files, uploaded_files)

    {:noreply, socket}
  end

  def handle_event("validate_upload", _params, socket) do
    num_remaining_uploads =
      length(socket.assigns.uploaded_files) - socket.assigns.uploads.demo.max_entries

    valid =
      Enum.uniq_by(socket.assigns.uploads.demo.entries, & &1.client_name)
      |> Enum.take(num_remaining_uploads)

    socket =
      Enum.reduce(socket.assigns.uploads.demo.entries, socket, fn entry, socket ->
        if entry in valid do
          socket
        else
          socket
          |> cancel_upload(:demo, entry.ref)
          |> put_flash(
            :error,
            "Uploaded files should be unique and cannot exceed #{socket.assigns.uploads.demo.max_entries} total files."
          )
        end
      end)

    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :demo, ref)}
  end

  def handle_event("cancel_upload", _params, socket) do
    socket =
      Enum.reduce(socket.assigns.uploads.demo.entries, socket, fn entry, socket ->
        cancel_upload(socket, :demo, entry.ref)
      end)

    {:noreply, socket}
  end

  defp join_refs(entries), do: Enum.join(entries, ",")
  def error_to_string(:too_large), do: "File too large!"
  def error_to_string(:not_accepted), do: "Bad file type!"

  defp to_megabytes_or_kilobytes(bytes) when is_integer(bytes) do
    case bytes do
      b when b < 1_048_576 ->
        kilobytes = (b / 1024) |> Float.round(1)

        if kilobytes < 1 do
          "#{kilobytes}MB"
        else
          "#{round(kilobytes)}KB"
        end

      _ ->
        megabytes = (bytes / 1_048_576) |> Float.round(1)
        "#{megabytes}MB"
    end
  end
end
