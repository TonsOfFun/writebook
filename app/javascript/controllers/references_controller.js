import { Controller } from "@hotwired/stimulus"

/**
 * References Controller
 *
 * Manages the research references panel, providing functionality to:
 * - Copy markdown links to clipboard
 * - Copy URLs to clipboard
 * - Refresh the references list
 * - Show visual feedback for copy actions
 */
export default class extends Controller {
  static targets = ["list", "count"]
  static values = {
    leafId: Number
  }

  connect() {
    console.log('[References] Controller connected')
  }

  /**
   * Copy a markdown-formatted link to the clipboard
   * Format: [Title](URL)
   */
  async copyMarkdownLink(event) {
    const button = event.currentTarget
    const markdown = button.dataset.markdown

    if (!markdown) return

    try {
      await navigator.clipboard.writeText(markdown)
      this.showCopiedFeedback(button, 'Copied!')
    } catch (error) {
      console.error('[References] Copy failed:', error)
      this.showCopiedFeedback(button, 'Failed')
    }
  }

  /**
   * Copy the plain URL to the clipboard
   */
  async copyUrl(event) {
    const button = event.currentTarget
    const url = button.dataset.url

    if (!url) return

    try {
      await navigator.clipboard.writeText(url)
      this.showCopiedFeedback(button, 'Copied!')
    } catch (error) {
      console.error('[References] Copy failed:', error)
      this.showCopiedFeedback(button, 'Failed')
    }
  }

  /**
   * Insert a markdown link into the editor at the current cursor position
   */
  insertLink(event) {
    const button = event.currentTarget
    const markdown = button.dataset.markdown

    if (!markdown) return

    const editor = document.querySelector('house-md.page__editor, house-md') ||
                   document.querySelector('textarea.page__editor')

    if (!editor) {
      console.error('[References] Editor not found')
      return
    }

    if (editor.tagName === 'HOUSE-MD') {
      // Insert at cursor position in CodeMirror
      const cm = editor.querySelector('.cm-editor')
      if (cm && cm.cmView) {
        const view = cm.cmView
        const state = view.state
        const pos = state.selection.main.head

        view.dispatch({
          changes: { from: pos, to: pos, insert: markdown },
          selection: { anchor: pos + markdown.length }
        })
      }
    } else if (editor.tagName === 'TEXTAREA') {
      const start = editor.selectionStart
      const end = editor.selectionEnd
      const text = editor.value

      editor.value = text.substring(0, start) + markdown + text.substring(end)
      editor.selectionStart = editor.selectionEnd = start + markdown.length
      editor.dispatchEvent(new Event('input', { bubbles: true }))
    }

    this.showCopiedFeedback(button, 'Inserted!')
  }

  /**
   * Refresh the references list from the server
   */
  async refresh() {
    // This could be implemented to fetch fresh references via Turbo Frame
    // For now, we'll reload the frame if it exists
    const frame = this.element.closest('turbo-frame')
    if (frame) {
      frame.reload()
    }
  }

  /**
   * Show visual feedback on a button after a copy action
   */
  showCopiedFeedback(button, message) {
    // Store original content
    const originalHTML = button.innerHTML

    // Show feedback
    button.innerHTML = `<span class="txt-small">${message}</span>`
    button.classList.add('reference-card__btn--success')

    // Restore after delay
    setTimeout(() => {
      button.innerHTML = originalHTML
      button.classList.remove('reference-card__btn--success')
    }, 1500)
  }
}
