import { Controller } from "@hotwired/stimulus"

/**
 * Assistant Controller
 *
 * Legacy controller that was previously used for AI assistant actions.
 * AI actions are now handled by the ai_modal_controller which provides
 * a modal interface for streaming AI interactions.
 *
 * This controller is kept for any non-modal AI functionality that may
 * be needed, such as image upload handling coordination.
 */
export default class extends Controller {
  connect() {
    console.log('Assistant controller connected')
  }

  disconnect() {
    console.log('Assistant controller disconnected')
  }
}
