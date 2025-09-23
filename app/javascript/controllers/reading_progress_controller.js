import { Controller } from "@hotwired/stimulus"
import { getReadingProgress } from "helpers/reading_progress_helpers"

export default class extends Controller {
  static values = { bookId: Number }
  static classes = [ "lastRead" ]

  connect() {
    this.#markLastReadLeaf()
  }

  #markLastReadLeaf() {
    const [ leafId ] = getReadingProgress(this.bookIdValue)
    const leafElement = leafId && this.element.querySelector(`#leaf_${leafId}`)

    if (leafElement) {
      leafElement.classList.add(this.lastReadClass)
    }
  }
}
