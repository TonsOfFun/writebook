import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

export default class extends Controller {
  connect() {
    console.log('Assistant controller connected')
    // Add event listeners to AI buttons
    this.bindAIButtons()
    this.bindImageUpload()
  }

  bindAIButtons() {
    // Find the toolbar that's part of the same editor structure
    const toolbar = document.querySelector('#house_toolbar, .house-toolbar')
    if (!toolbar) {
      console.error('Toolbar not found')
      return
    }

    // Bind click events to AI buttons
    toolbar.querySelectorAll('[data-action^="ai-"]').forEach(button => {
      button.addEventListener('click', (e) => {
        e.preventDefault()
        const action = button.dataset.action
        console.log('AI button clicked:', action)
        this.handleAIAction(action)
      })
    })
  }

  bindImageUpload() {
    // Find the image upload button/input
    const uploadButton = document.querySelector('[data-action="upload-image"], .file-upload, input[type="file"]')
    if (uploadButton) {
      // If it's an input, add change listener
      if (uploadButton.tagName === 'INPUT') {
        uploadButton.addEventListener('change', (e) => this.handleImageUpload(e))
      } else {
        // Create a hidden file input if needed
        let fileInput = uploadButton.querySelector('input[type="file"]')
        if (!fileInput) {
          fileInput = document.createElement('input')
          fileInput.type = 'file'
          fileInput.accept = 'image/*'
          fileInput.style.display = 'none'
          uploadButton.appendChild(fileInput)

          uploadButton.addEventListener('click', () => fileInput.click())
        }
        fileInput.addEventListener('change', (e) => this.handleImageUpload(e))
      }
    }
  }

  async handleImageUpload(event) {
    const file = event.target.files[0]
    if (!file || !file.type.startsWith('image/')) {
      return
    }

    console.log('Uploading image for caption:', file.name)

    // Show loading state
    this.showLoading('upload-image')

    try {
      // Create FormData for file upload
      const formData = new FormData()
      formData.append('file', file)
      formData.append('detail_level', 'medium')

      // Upload and get caption
      const response = await fetch('/assistants/image/caption', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: formData
      })

      if (response.ok) {
        const data = await response.json()
        console.log('Caption generated:', data.caption)

        // Insert image with caption into editor
        this.insertImageWithCaption(file, data.caption, data.filename)
      } else {
        throw new Error('Failed to generate caption')
      }
    } catch (error) {
      console.error('Image upload error:', error)
      alert('Failed to upload image and generate caption. Please try again.')
    } finally {
      this.hideLoading()
      // Reset file input
      event.target.value = ''
    }
  }

  insertImageWithCaption(file, caption, filename) {
    const editor = this.getEditor()
    if (!editor) return

    // Create a local URL for the image
    const imageUrl = URL.createObjectURL(file)

    // Create markdown for image with caption
    const imageMarkdown = `\n![${caption}](${imageUrl})\n*${caption}*\n\n`

    // Insert at current cursor position
    if (editor.tagName === 'HOUSE-MD') {
      const currentContent = editor.value || ''
      editor.value = currentContent + imageMarkdown
      editor.dispatchEvent(new Event('input', { bubbles: true }))
      editor.dispatchEvent(new Event('change', { bubbles: true }))
    } else {
      const position = editor.selectionStart || editor.value.length
      const text = editor.value
      editor.value = text.substring(0, position) + imageMarkdown + text.substring(position)
      editor.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }

  async handleAIAction(action) {
    const editor = this.getEditor()
    if (!editor) {
      console.error('Editor not found')
      return
    }

    const selectedText = this.getSelectedText(editor)
    let content = selectedText

    // Handle different editor types
    if (editor.tagName === 'HOUSE-MD') {
      // House-MD stores its value in the .value property
      content = content || editor.value
    } else {
      content = content || editor.value
    }

    if (!content || !content.trim()) {
      alert('Please select some text or have content in the editor')
      return
    }

    // Show loading state
    this.showLoading(action)

    try {
      let response

      switch(action) {
        case 'ai-improve':
          response = await this.improveWriting(content)
          break
        case 'ai-grammar':
          response = await this.checkGrammar(content)
          break
        case 'ai-expand':
          response = await this.expandText(content)
          break
        case 'ai-summarize':
          response = await this.summarizeText(content)
          break
        case 'ai-style':
          response = await this.adjustStyle(content)
          break
        case 'ai-brainstorm':
          response = await this.brainstormIdeas(content)
          break
        default:
          throw new Error(`Unknown action: ${action}`)
      }

      // Handle the response
      // The @rails/request.js library returns a response with a json property that is a Promise
      if (response.ok) {
        const data = await response.json // json is a Promise that needs to be awaited
        this.applyAIResult(data, selectedText !== null)
      } else {
        throw new Error('AI request failed')
      }
    } catch (error) {
      console.error('AI Assistant error:', error)
      alert('An error occurred while processing your request. Please try again.')
    } finally {
      this.hideLoading()
    }
  }

  async improveWriting(content) {
    return await post('/assistants/writing/improve', {
      body: JSON.stringify({ content }),
      responseKind: 'json',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
  }

  async checkGrammar(content) {
    return await post('/assistants/writing/grammar', {
      body: JSON.stringify({ content }),
      responseKind: 'json',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
  }

  async expandText(content) {
    return await post('/assistants/writing/expand', {
      body: JSON.stringify({ content }),
      responseKind: 'json',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
  }

  async summarizeText(content) {
    return await post('/assistants/writing/summarize', {
      body: JSON.stringify({ content }),
      responseKind: 'json',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
  }

  async adjustStyle(content, style = null) {
    return await post('/assistants/writing/style', {
      body: JSON.stringify({ content, style_guide: style }),
      responseKind: 'json',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
  }

  async brainstormIdeas(topic) {
    return await post('/assistants/writing/brainstorm', {
      body: JSON.stringify({ topic, number_of_ideas: 5 }),
      responseKind: 'json',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
  }

  applyAIResult(data, replaceSelection) {
    const editor = this.getEditor()
    if (!editor) return

    let newContent = ''

    // Extract the appropriate content from the response
    if (data.improved_content) {
      newContent = data.improved_content
    } else if (data.corrected_content) {
      newContent = data.corrected_content
    } else if (data.expanded_content) {
      newContent = data.expanded_content
    } else if (data.styled_content) {
      newContent = data.styled_content
    } else if (data.summary) {
      // For summaries, we might want to insert at cursor instead of replace
      newContent = `\n\n## Summary\n\n${data.summary}\n\n`
      replaceSelection = false
    } else if (data.ideas) {
      // For brainstorming, format as a list
      newContent = `\n\n## Ideas\n\n${data.ideas}\n\n`
      replaceSelection = false
    }

    // Handle House MD editor
    if (editor.tagName === 'HOUSE-MD') {
      const currentContent = editor.value

      // For House MD, replace or append content
      let updatedContent
      if (replaceSelection) {
        // If we have selected text, replace it
        const selection = window.getSelection()
        if (selection && selection.toString()) {
          const selectedText = selection.toString()
          updatedContent = currentContent.replace(selectedText, newContent)
        } else {
          // No selection, replace all
          updatedContent = newContent
        }
      } else {
        // Append the new content
        updatedContent = currentContent + newContent
      }

      // Update the house-md value
      editor.value = updatedContent

      // Trigger input and change events for House MD
      editor.dispatchEvent(new Event('input', { bubbles: true }))
      editor.dispatchEvent(new Event('change', { bubbles: true }))
    } else {
      // Handle regular textarea
      if (replaceSelection) {
        // Replace selected text
        const start = editor.selectionStart
        const end = editor.selectionEnd
        const text = editor.value
        editor.value = text.substring(0, start) + newContent + text.substring(end)

        // Set cursor position after inserted text
        const newPosition = start + newContent.length
        editor.setSelectionRange(newPosition, newPosition)
      } else {
        // Insert at cursor position
        const position = editor.selectionStart
        const text = editor.value
        editor.value = text.substring(0, position) + newContent + text.substring(position)

        // Set cursor position after inserted text
        const newPosition = position + newContent.length
        editor.setSelectionRange(newPosition, newPosition)
      }

      // Trigger input event to notify any listeners
      editor.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }

  getEditor() {
    // Try to find the House MD editor
    const houseMD = document.querySelector('house-md.page__editor, house-md')
    if (houseMD) return houseMD

    // Try to find regular textarea
    return this.element.closest('.house-editor')?.querySelector('textarea') ||
           this.element.querySelector('textarea') ||
           document.querySelector('textarea.page__editor')
  }

  getSelectedText(editor) {
    // Handle House MD editor
    if (editor.tagName === 'HOUSE-MD') {
      // Try to get selected text from the window selection
      const selection = window.getSelection()
      if (selection && selection.toString()) {
        return selection.toString()
      }
      // If no selection, return empty string
      return ''
    }

    // Handle regular textarea
    const start = editor.selectionStart
    const end = editor.selectionEnd

    if (start !== end) {
      return editor.value.substring(start, end)
    }

    return null
  }

  showLoading(action) {
    // Add loading class to the button
    const button = this.element.querySelector(`[data-action="${action}"]`)
    if (button) {
      button.classList.add('loading')
      button.disabled = true
    }

    // Show loading indicator if available
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.remove('hidden')
    }
  }

  hideLoading() {
    // Remove loading class from all buttons
    this.element.querySelectorAll('[data-action^="ai-"]').forEach(button => {
      button.classList.remove('loading')
      button.disabled = false
    })

    // Hide loading indicator
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.add('hidden')
    }
  }
}