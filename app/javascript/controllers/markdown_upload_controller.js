import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["filePicker", "editor"]

  connect() {
    console.log("Markdown upload controller connected")
    // Only setup once, check if already initialized
    if (!this.element.dataset.uploadInitialized) {
      this.setupFileUpload()
      this.element.dataset.uploadInitialized = 'true'
    }

    // Initialize ActionCable consumer
    this.cable = window.App || (window.App = {})
    if (!this.cable.cable) {
      this.cable.cable = createConsumer()
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

    // If streaming is enabled, add placeholder caption
    let captionMarkdown = ''
    if (uploadResult.streamId) {
      captionMarkdown = '\n*Generating caption...*'
      // Start streaming caption
      this.streamCaption(uploadResult.streamId, uploadResult.fileUrl)
    }

    // Insert at cursor position or at the end
    const newContent = currentValue + '\n' + imageMarkdown + captionMarkdown + '\n\n'

    // Update the editor
    houseMd.value = newContent

    // Trigger input event to update preview
    houseMd.dispatchEvent(new Event('input', { bubbles: true }))
    houseMd.dispatchEvent(new Event('change', { bubbles: true }))
  }

  streamCaption(streamId, imageUrl) {
    const houseMd = document.querySelector('house-md')
    if (!houseMd) return

    console.log('[Caption Streaming] Starting for stream_id:', streamId)

    let accumulatedCaption = ''

    // Subscribe to ActionCable for caption streaming
    const subscription = this.cable.cable.subscriptions.create(
      { channel: "AssistantStreamChannel", stream_id: streamId },
      {
        connected: () => {
          console.log('[Caption Streaming] Connected to AssistantStreamChannel with stream_id:', streamId)
        },
        disconnected: () => {
          console.log('[Caption Streaming] Disconnected from AssistantStreamChannel')
        },
        received: (message) => {
          console.log('[Caption Streaming] Message received:', message)

          if (message.content) {
            // Append new caption chunk
            accumulatedCaption += message.content
            console.log('[Caption Streaming] Accumulated caption:', accumulatedCaption)

            // Update the caption in the editor
            this.updateCaption(imageUrl, accumulatedCaption)
          } else if (message.done) {
            console.log('[Caption Streaming] Streaming complete. Final caption:', accumulatedCaption)
            // Streaming complete - final update
            this.updateCaption(imageUrl, accumulatedCaption)
            subscription.unsubscribe()
          } else if (message.error) {
            console.error('[Caption Streaming] Error:', message.error)
            this.updateCaption(imageUrl, 'Error generating caption')
            subscription.unsubscribe()
          }
        }
      }
    )
  }

  updateCaption(imageUrl, caption) {
    const houseMd = document.querySelector('house-md')
    if (!houseMd) return

    // Find the image markdown and update the caption below it
    const currentContent = houseMd.value || ''
    const imageMarkdown = currentContent.split('\n').find(line => line.includes(imageUrl))

    if (imageMarkdown) {
      // Build the pattern to find and replace the caption
      // Pattern: image line followed by caption line
      const escapedUrl = imageUrl.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
      const pattern = new RegExp(
        `(!\\[.*?\\]\\(${escapedUrl}\\))\\n\\*.*?\\*`,
        'g'
      )

      // Replace with image and new caption
      const newContent = currentContent.replace(
        pattern,
        `$1\n*${caption}*`
      )

      // Update the editor
      houseMd.value = newContent

      // Trigger input event to update preview
      houseMd.dispatchEvent(new Event('input', { bubbles: true }))
    }
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