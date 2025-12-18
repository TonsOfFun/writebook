import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "container", "pageInfo", "prevBtn", "nextBtn"]
  static values = {
    url: String,
    scale: { type: Number, default: 1.5 }
  }

  async connect() {
    if (!this.urlValue) return

    this.currentPage = 1
    this.pdfDoc = null
    this.pageRendering = false
    this.pageNumPending = null

    try {
      await this.loadPdf()
    } catch (error) {
      console.error("Failed to load PDF:", error)
      this.showError("Failed to load PDF document")
    }
  }

  async loadPdf() {
    // Dynamically import PDF.js
    const pdfjsLib = await import("pdfjs-dist")

    // Set worker source
    pdfjsLib.GlobalWorkerOptions.workerSrc = "https://cdn.jsdelivr.net/npm/pdfjs-dist@4.0.379/build/pdf.worker.min.mjs"

    // Load the PDF document
    const loadingTask = pdfjsLib.getDocument(this.urlValue)
    this.pdfDoc = await loadingTask.promise

    this.totalPages = this.pdfDoc.numPages
    this.updatePageInfo()
    this.updateButtonStates()

    // Render the first page
    await this.renderPage(this.currentPage)
  }

  async renderPage(pageNum) {
    if (this.pageRendering) {
      this.pageNumPending = pageNum
      return
    }

    this.pageRendering = true

    try {
      const page = await this.pdfDoc.getPage(pageNum)

      // Calculate scale to fit container width
      const containerWidth = this.containerTarget.clientWidth - 40 // padding
      const viewport = page.getViewport({ scale: 1 })
      const scale = Math.min(this.scaleValue, containerWidth / viewport.width)
      const scaledViewport = page.getViewport({ scale })

      // Set canvas dimensions
      const canvas = this.canvasTarget
      const context = canvas.getContext("2d")
      canvas.height = scaledViewport.height
      canvas.width = scaledViewport.width

      // Render the page
      const renderContext = {
        canvasContext: context,
        viewport: scaledViewport
      }

      await page.render(renderContext).promise

      this.pageRendering = false

      // Render pending page if any
      if (this.pageNumPending !== null) {
        await this.renderPage(this.pageNumPending)
        this.pageNumPending = null
      }
    } catch (error) {
      console.error("Failed to render page:", error)
      this.pageRendering = false
    }
  }

  previousPage() {
    if (this.currentPage <= 1) return
    this.currentPage--
    this.queueRenderPage(this.currentPage)
  }

  nextPage() {
    if (this.currentPage >= this.totalPages) return
    this.currentPage++
    this.queueRenderPage(this.currentPage)
  }

  queueRenderPage(pageNum) {
    if (this.pageRendering) {
      this.pageNumPending = pageNum
    } else {
      this.renderPage(pageNum)
    }
    this.updatePageInfo()
    this.updateButtonStates()
  }

  updatePageInfo() {
    if (this.hasPageInfoTarget) {
      this.pageInfoTarget.textContent = `Page ${this.currentPage} of ${this.totalPages}`
    }
  }

  updateButtonStates() {
    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.disabled = this.currentPage <= 1
    }
    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.disabled = this.currentPage >= this.totalPages
    }
  }

  showError(message) {
    if (this.hasContainerTarget) {
      this.containerTarget.innerHTML = `
        <div class="pdf-error pad txt-center">
          <p class="txt-error">${message}</p>
          <p class="txt-small txt-muted">Try downloading the file instead.</p>
        </div>
      `
    }
  }
}
