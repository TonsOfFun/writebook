import { Controller } from "@hotwired/stimulus"

// Enhances house-md with caption support for image uploads
export default class extends Controller {
  connect() {
    this.captionData = null
    this.enhanceHouseMd()
    this.interceptUploadResponse()
  }

  interceptUploadResponse() {
    // Monitor XHR responses to capture caption data
    const self = this
    const originalSend = XMLHttpRequest.prototype.send

    XMLHttpRequest.prototype.send = function(...args) {
      this.addEventListener('load', function() {
        // Check if this is an upload response with a caption
        if (this.responseURL && this.responseURL.includes('/uploads') &&
            this.status === 201) {
          try {
            const response = JSON.parse(this.responseText)
            if (response.caption && response.fileUrl) {
              // Store caption data keyed by fileUrl
              self.captionData = {
                fileUrl: response.fileUrl,
                caption: response.caption
              }
            }
          } catch (e) {
            // Not JSON or parsing error, ignore
          }
        }
      })

      return originalSend.apply(this, args)
    }
  }

  enhanceHouseMd() {
    const houseMd = this.element.querySelector('house-md')
    if (!houseMd) return

    // Wait for house-md to be fully initialized
    setTimeout(() => {
      if (!houseMd.document) return

      const originalInsertFile = houseMd.document.insertFile.bind(houseMd.document)
      const self = this

      // Override insertFile to add caption support
      houseMd.document.insertFile = async function(fileName, fileUrl, mimetype) {
        // First call the original method to insert the image
        await originalInsertFile(fileName, fileUrl, mimetype)

        // Check if we have caption data for this URL
        if (self.captionData && self.captionData.fileUrl === fileUrl) {
          const caption = self.captionData.caption
          const editor = houseMd

          // Get current value and find the just-inserted image
          const currentValue = editor.value || ''
          const imageMarkdown = `![${fileName}](${fileUrl})`

          if (currentValue.includes(imageMarkdown)) {
            // Replace with image + caption
            const imageWithCaption = `${imageMarkdown}\n*${caption}*`
            editor.value = currentValue.replace(imageMarkdown, imageWithCaption)

            // Trigger events to update the preview
            editor.dispatchEvent(new Event('input', { bubbles: true }))
            editor.dispatchEvent(new Event('change', { bubbles: true }))
          }

          // Clear the caption data after use
          self.captionData = null
        }
      }
    }, 100) // Small delay to ensure house-md is initialized
  }
}