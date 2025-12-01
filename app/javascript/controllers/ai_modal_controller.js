import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

/**
 * AI Modal Controller
 *
 * Provides a modal interface for all streaming AI interactions.
 * Shows real-time streaming content and allows users to apply, copy, or discard results.
 */
export default class extends Controller {
  static targets = ["dialog", "content", "status", "applyButton", "copyButton"]
  static values = {
    action: String,
    originalContent: String
  }

  connect() {
    console.log('[AI Modal] Controller connected')
    this.cable = window.App || (window.App = {})
    if (!this.cable.cable) {
      this.cable.cable = createConsumer()
    }
    this.subscription = null
    this.accumulatedContent = ''
    this.isStreaming = false

    // Listen for global AI action events (from toolbar buttons outside controller scope)
    this.handleGlobalAiAction = this.handleGlobalAiAction.bind(this)
    document.addEventListener('ai-modal:perform', this.handleGlobalAiAction)

    // Track content changes when user edits
    this.handleContentInput = this.handleContentInput.bind(this)
    this.contentTarget.addEventListener('input', this.handleContentInput)
  }

  disconnect() {
    document.removeEventListener('ai-modal:perform', this.handleGlobalAiAction)
    this.contentTarget.removeEventListener('input', this.handleContentInput)
    this.cleanup()
  }

  /**
   * Track user edits to the content
   */
  handleContentInput() {
    // Update accumulated content when user edits
    this.accumulatedContent = this.contentTarget.innerText
  }

  /**
   * Handle AI action triggered from anywhere on the page
   */
  handleGlobalAiAction(event) {
    const { actionType } = event.detail
    console.log('[AI Modal] Global action received:', actionType)

    const editor = this.getEditor()
    if (!editor) {
      console.error('[AI Modal] Editor not found')
      return
    }

    const content = this.getEditorContent(editor)
    if (!content || !content.trim()) {
      alert('Please add some content to the editor first')
      return
    }

    this.originalContentValue = content
    this.actionValue = actionType

    this.openModal(actionType)
    this.startStreaming(actionType, content)
  }

  /**
   * Open the modal and start an AI action
   * Called via data-action="ai-modal#perform"
   */
  perform(event) {
    event.preventDefault()

    const button = event.currentTarget
    const actionType = button.dataset.aiAction
    const editor = this.getEditor()

    if (!editor) {
      console.error('[AI Modal] Editor not found')
      return
    }

    // Get content from editor
    const content = this.getEditorContent(editor)
    if (!content || !content.trim()) {
      alert('Please add some content to the editor first')
      return
    }

    // Store original content for potential restoration
    this.originalContentValue = content
    this.actionValue = actionType

    // Open modal and start streaming
    this.openModal(actionType)
    this.startStreaming(actionType, content)
  }

  /**
   * Open modal for image caption streaming
   * Called when an image is uploaded
   */
  streamCaption(event) {
    const { streamId, imageUrl, fileName } = event.detail

    this.actionValue = 'caption'
    this.openModal('caption', fileName)
    this.subscribeToStream(streamId)
  }

  openModal(actionType, context = '') {
    // Reset state
    this.accumulatedContent = ''
    this.isStreaming = true

    // Update UI
    this.contentTarget.innerHTML = ''
    this.contentTarget.contentEditable = 'false'  // Disable editing while streaming
    this.setStatus(this.getActionLabel(actionType), true)
    this.applyButtonTarget.disabled = true
    this.copyButtonTarget.disabled = true

    // Show modal
    this.dialogTarget.showModal()
  }

  closeModal() {
    this.cleanup()
    this.dialogTarget.close()
  }

  async startStreaming(actionType, content) {
    try {
      // Make request to get stream_id
      const response = await fetch('/assistants/stream', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          action_type: actionType,
          content: content
        })
      })

      const data = await response.json()

      if (data.error) {
        this.showError(data.error)
        return
      }

      // Small delay to ensure subscription is ready before server starts streaming
      await new Promise(resolve => setTimeout(resolve, 100))

      this.subscribeToStream(data.stream_id)
    } catch (error) {
      console.error('[AI Modal] Request error:', error)
      this.showError('Failed to start AI processing')
    }
  }

  subscribeToStream(streamId) {
    console.log('[AI Modal] Subscribing to stream:', streamId)

    this.subscription = this.cable.cable.subscriptions.create(
      { channel: "AssistantStreamChannel", stream_id: streamId },
      {
        connected: () => {
          console.log('[AI Modal] Connected to stream')
        },
        disconnected: () => {
          console.log('[AI Modal] Disconnected from stream')
        },
        received: (message) => {
          this.handleStreamMessage(message)
        }
      }
    )
  }

  handleStreamMessage(message) {
    console.log('[AI Modal] Message received:', message)

    if (message.content) {
      this.accumulatedContent += message.content
      // Render as markdown preview while streaming
      this.contentTarget.innerHTML = this.renderMarkdown(this.accumulatedContent)

      // Auto-scroll to bottom
      this.contentTarget.scrollTop = this.contentTarget.scrollHeight
    } else if (message.done) {
      this.onStreamComplete()
    } else if (message.error) {
      this.showError(message.error)
    }
  }

  onStreamComplete() {
    console.log('[AI Modal] Stream complete')
    this.isStreaming = false
    this.setStatus('Complete', false)
    this.applyButtonTarget.disabled = false
    this.copyButtonTarget.disabled = false

    // Enable editing now that streaming is complete
    this.contentTarget.contentEditable = 'true'

    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  /**
   * Apply the generated content to the editor
   */
  apply() {
    const editor = this.getEditor()
    if (!editor || !this.accumulatedContent) return

    // Clean up any markdown code fences if present
    let cleanContent = this.accumulatedContent.trim()
    if (cleanContent.startsWith('```')) {
      cleanContent = cleanContent.replace(/^```\w*\n?/, '').replace(/\n?```$/, '')
    }

    // Update editor
    if (editor.tagName === 'HOUSE-MD') {
      editor.value = cleanContent
      editor.dispatchEvent(new Event('input', { bubbles: true }))
    } else {
      editor.value = cleanContent
      editor.dispatchEvent(new Event('input', { bubbles: true }))
    }

    this.closeModal()
  }

  /**
   * Copy content to clipboard
   */
  async copy() {
    if (!this.accumulatedContent) return

    try {
      await navigator.clipboard.writeText(this.accumulatedContent)

      // Visual feedback
      const originalText = this.copyButtonTarget.textContent
      this.copyButtonTarget.textContent = 'Copied!'
      setTimeout(() => {
        this.copyButtonTarget.textContent = originalText
      }, 1500)
    } catch (error) {
      console.error('[AI Modal] Copy failed:', error)
    }
  }

  /**
   * Discard and close
   */
  discard() {
    this.closeModal()
  }

  showError(message) {
    this.isStreaming = false
    this.setStatus('Error', false)
    this.contentTarget.innerHTML = `<span class="ai-modal__error">${message}</span>`
    this.applyButtonTarget.disabled = true
    this.copyButtonTarget.disabled = true
  }

  setStatus(text, isLoading) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = text
      this.statusTarget.classList.toggle('ai-modal__status--loading', isLoading)
    }
  }

  getActionLabel(actionType) {
    const labels = {
      improve: 'Improving writing...',
      grammar: 'Checking grammar...',
      expand: 'Expanding text...',
      summarize: 'Summarizing...',
      style: 'Adjusting style...',
      brainstorm: 'Brainstorming...',
      caption: 'Generating caption...'
    }
    return labels[actionType] || 'Processing...'
  }

  /**
   * Simple markdown to HTML renderer for preview
   */
  renderMarkdown(text) {
    if (!text) return ''

    // First, strip outer markdown code fences if present (AI often wraps response in ```markdown)
    let content = text.trim()
    if (content.startsWith('```')) {
      content = content.replace(/^```\w*\n?/, '').replace(/\n?```$/, '')
    }

    // Escape HTML to prevent XSS
    let html = content
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')

    // Code blocks (```...```) - preserve inner code blocks
    html = html.replace(/```(\w*)\n?([\s\S]*?)```/g, '<pre><code>$2</code></pre>')

    // Inline code (`...`)
    html = html.replace(/`([^`]+)`/g, '<code>$1</code>')

    // Headers (# ## ###)
    html = html.replace(/^### (.+)$/gm, '<h3>$1</h3>')
    html = html.replace(/^## (.+)$/gm, '<h2>$1</h2>')
    html = html.replace(/^# (.+)$/gm, '<h1>$1</h1>')

    // Bold (**...**)
    html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')

    // Italic (*...*)
    html = html.replace(/\*([^*]+)\*/g, '<em>$1</em>')

    // Blockquotes (> ...)
    html = html.replace(/^&gt; (.+)$/gm, '<blockquote>$1</blockquote>')

    // Unordered lists (- ...)
    html = html.replace(/^- (.+)$/gm, '<li>$1</li>')

    // Ordered lists (1. ...)
    html = html.replace(/^\d+\. (.+)$/gm, '<li>$1</li>')

    // Wrap consecutive list items in ul/ol
    html = html.replace(/(<li>.*<\/li>\n?)+/g, '<ul>$&</ul>')

    // Paragraphs (double newlines)
    html = html.replace(/\n\n+/g, '</p><p>')

    // Single newlines to <br> (except after block elements)
    html = html.replace(/(?<!\>)\n(?!<)/g, '<br>')

    // Wrap in paragraph if not already wrapped in a block element
    if (!html.match(/^<(h[1-6]|p|ul|ol|pre|blockquote)/)) {
      html = '<p>' + html + '</p>'
    }

    // Clean up empty paragraphs and fix paragraph nesting
    html = html.replace(/<p><\/p>/g, '')
    html = html.replace(/<p>(<h[1-6]>)/g, '$1')
    html = html.replace(/(<\/h[1-6]>)<\/p>/g, '$1')

    return html
  }

  getEditor() {
    return document.querySelector('house-md.page__editor, house-md') ||
           document.querySelector('textarea.page__editor')
  }

  getEditorContent(editor) {
    if (editor.tagName === 'HOUSE-MD') {
      return editor.value
    }
    return editor.value
  }

  cleanup() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
    this.isStreaming = false
    this.accumulatedContent = ''
  }
}
