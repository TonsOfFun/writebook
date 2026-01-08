import { Controller } from "@hotwired/stimulus"

/**
 * References Panel Controller
 *
 * Controls the slide-out references panel behavior:
 * - Toggle open/close
 * - Handle keyboard escape to close
 * - Manage focus trap when open
 */
export default class extends Controller {
  static targets = ["panel"]

  connect() {
    console.log('[ReferencesPanel] Controller connected')

    // Listen for global toggle event
    this.handleToggle = this.handleToggle.bind(this)
    document.addEventListener('references-panel:toggle', this.handleToggle)

    // Handle escape key
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener('references-panel:toggle', this.handleToggle)
    document.removeEventListener('keydown', this.handleKeydown)
  }

  handleToggle() {
    this.toggle()
  }

  handleKeydown(event) {
    if (event.key === 'Escape' && this.isOpen) {
      this.close()
    }
  }

  toggle() {
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.panelTarget.classList.add('references-panel--open')
    document.body.classList.add('has-references-panel')
  }

  close() {
    this.panelTarget.classList.remove('references-panel--open')
    document.body.classList.remove('has-references-panel')
  }

  get isOpen() {
    return this.panelTarget.classList.contains('references-panel--open')
  }
}
