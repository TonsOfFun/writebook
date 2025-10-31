import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filePicker", "editor"]

  connect() {
    console.log("Markdown upload controller connected")
    // Only setup once, check if already initialized
    if (!this.element.dataset.uploadInitialized) {
      this.setupFileUpload()
      this.element.dataset.uploadInitialized = 'true'
    }
  }

  setupFileUpload() {
    // Find the file upload button in the toolbar
    const uploadButton = document.querySelector('[title="Upload File"]')
    if (uploadButton && !uploadButton.dataset.customHandler) {
      // Mark as having custom handler
      uploadButton.dataset.customHandler = 'true'

      // Add our custom click handler
      uploadButton.addEventListener('click', (e) => {
        e.preventDefault()
        e.stopPropagation()
        this.triggerFileSelect()
      })
    }
  }

  triggerFileSelect() {
    // Create a temporary file input
    const fileInput = document.createElement('input')
    fileInput.type = 'file'
    fileInput.accept = 'image/*'
    fileInput.multiple = true

    fileInput.addEventListener('change', async (e) => {
      const files = e.target.files
      if (files.length > 0) {
        for (const file of files) {
          await this.uploadFile(file)
        }
      }
    })

    // Trigger the file selection dialog
    fileInput.click()
  }

  async uploadFile(file) {
    const houseMd = document.querySelector('house-md')
    if (!houseMd || !houseMd.dataset.uploadsUrl) {
      console.error('No house-md element or upload URL found')
      return
    }

    // Show loading state
    this.showUploadingState()

    try {
      // Create FormData
      const formData = new FormData()
      formData.append('file', file)

      // Get CSRF token
      const csrfToken = document.querySelector('[name="csrf-token"]')?.content

      // Upload the file
      const response = await fetch(houseMd.dataset.uploadsUrl, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json'
        },
        body: formData
      })

      if (!response.ok) {
        throw new Error(`Upload failed: ${response.status}`)
      }

      const result = await response.json()

      // Insert the image markdown and caption into the editor
      if (result.fileUrl) {
        this.insertImageIntoEditor(result)
      } else {
        console.error('No file URL in response')
      }
    } catch (error) {
      console.error('Upload error:', error)
      alert('Failed to upload image. Please try again.')
    } finally {
      this.hideUploadingState()
    }
  }

  insertImageIntoEditor(uploadResult) {
    const houseMd = document.querySelector('house-md')
    if (!houseMd) return

    // Get current content
    const currentValue = houseMd.value || ''

    // Build the markdown for the image
    const imageMarkdown = `![${uploadResult.fileName || 'Image'}](${uploadResult.fileUrl})`

    // Add caption if available
    const captionMarkdown = uploadResult.caption ? `\n*${uploadResult.caption}*` : ''

    // Insert at cursor position or at the end
    const newContent = currentValue + '\n' + imageMarkdown + captionMarkdown + '\n\n'

    // Update the editor
    houseMd.value = newContent

    // Trigger input event to update preview
    houseMd.dispatchEvent(new Event('input', { bubbles: true }))
    houseMd.dispatchEvent(new Event('change', { bubbles: true }))
  }

  showUploadingState() {
    // Add visual feedback during upload
    const uploadButton = document.querySelector('[title="Upload File"]')
    if (uploadButton) {
      uploadButton.style.opacity = '0.5'
      uploadButton.style.pointerEvents = 'none'
    }
  }

  hideUploadingState() {
    // Remove visual feedback
    const uploadButton = document.querySelector('[title="Upload File"]')
    if (uploadButton) {
      uploadButton.style.opacity = '1'
      uploadButton.style.pointerEvents = 'auto'
    }
  }
}