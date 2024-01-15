// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket, UploadEntry } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let Hooks = {};
Hooks.GatherPreviews = {
  async convertBlobUrlToBase64(blobUrl) {
    const response = await fetch(blobUrl);
    const blob = await response.blob();

    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => resolve(reader.result);
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  },
  async getPreviews() {
    const elements = document.querySelectorAll('[id^="phx-preview-"]');
    const previews = {};
    for (const el of elements) {
      const src = el.getAttribute("src");
      const dataPhxEntryRef = el.getAttribute("data-phx-entry-ref");

      previews[dataPhxEntryRef] = src.startsWith("blob:")
        ? await this.convertBlobUrlToBase64(src)
        : src;
    }
    console.log("gathering previews");
    console.log(previews);
    return previews;
  },
  mounted() {
    this.handleEvent("gatherPreviews", (_params) => {
      console.log("gatherPreviews Event");
      this.getPreviews().then((previews) => {
        this.pushEvent("update_preview_srcs", { srcs: previews });
      });
    });
  },
};

Hooks.LiveFileUpload = {
  activeRefs() {
    return this.el.getAttribute("data-phx-active-refs");
  },

  preflightedRefs() {
    return this.el.getAttribute("data-phx-preflighted-refs");
  },

  mounted() {
    this.preflightedWas = this.preflightedRefs();
    let pdfjsLib = window["pdfjs-dist/build/pdf"];
    // Ensure pdfjsLib is available globally
    if (typeof pdfjsLib === "undefined") {
      console.error("pdf.js is not loaded");
      return;
    }
    // Use the global `pdfjsLib` to access PDFJS functionalities
    pdfjsLib.GlobalWorkerOptions.workerSrc =
      "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js";
    this.el.addEventListener("input", (event) => {
      const files = event.target.files;
      for (const file of files) {
        if (file.type === "application/pdf") {
          const fileReader = new FileReader();
          fileReader.onload = (e) => {
            const typedarray = new Uint8Array(e.target.result);
            // Load the PDF file
            pdfjsLib.getDocument(typedarray).promise.then((pdf) => {
              // Assuming you want to preview the first page of each PDF
              pdf.getPage(1).then((page) => {
                const scale = 1.5;
                const viewport = page.getViewport({ scale: scale });
                const canvas = document.createElement("canvas");
                const context = canvas.getContext("2d");
                canvas.height = viewport.height;
                canvas.width = viewport.width;

                // Render PDF page into canvas context
                const renderContext = {
                  canvasContext: context,
                  viewport: viewport,
                };
                page.render(renderContext).promise.then(() => {
                  // Convert canvas to image and set as source for the element
                  const imgSrc = canvas.toDataURL("image/png");
                  let upload_entry = new UploadEntry(
                    this.el,
                    file,
                    this.__view
                  );
                  if (
                    (imgEl = document.getElementById(
                      `phx-preview-${upload_entry.ref}`
                    ))
                  ) {
                    imgEl.setAttribute("src", imgSrc);
                  } else {
                    this.el.setAttribute(
                      `pdf-preview-${upload_entry.ref}`,
                      imgSrc
                    );
                  }
                });
              });
            });
          };
          fileReader.readAsArrayBuffer(file);
        }
      }
    });
  },
  updated() {
    let newPreflights = this.preflightedRefs();
    if (this.preflightedWas !== newPreflights) {
      this.preflightedWas = newPreflights;
      if (newPreflights === "") {
        this.__view.cancelSubmit(this.el.form);
      }
    }

    if (this.activeRefs() === "") {
      this.el.value = null;
    }
    this.el.dispatchEvent(new CustomEvent("phx:live-file:updated"));
  },
};

Hooks.LivePdfPreview = {
  mounted() {
    this.ref = this.el.getAttribute("data-phx-entry-ref");
    this.inputEl = document.getElementById(
      this.el.getAttribute("data-phx-upload-ref")
    );
    let src = this.inputEl.getAttribute(`pdf-preview-${this.ref}`);
    if (!src) {
      src = "https://poainc.org/wp-content/uploads/2018/06/pdf-placeholder.png";
    } else {
      this.inputEl.removeAttribute(`pdf-preview-${this.ref}`);
    }
    this.el.src = src;
    this.url = src;
  },
  destroyed() {
    if (this.url) {
      URL.revokeObjectURL(this.url);
    }
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
