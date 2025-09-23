import { Controller } from "@hotwired/stimulus"
import { nextFrame } from "helpers/timing_helpers"
import { getReadingProgress, storeReadingProgress } from "helpers/reading_progress_helpers"

export default class extends Controller {
  static values = { bookId: Number, leafId: Number }

  async connect() {
    this.paragraphs = Array.from(document.querySelectorAll("main p"))

    this.visibleParagraphs = new Set()
    this.lastReadParagraphIndex = 0

    await nextFrame()
    this.#scrollToLastReadParagraph()

    await nextFrame()
    this.#observeReadingProgress()
    this.#storeProgress()
  }

  disconnect() {
    this.observer.disconnect()
  }

  #scrollToLastReadParagraph() {
    const [ leafId, lastReadParagraphIndex ] = getReadingProgress(this.bookIdValue)

    if (leafId === this.leafIdValue && lastReadParagraphIndex > 0) {
      const lastReadParagraph = this.paragraphs[lastReadParagraphIndex]
      lastReadParagraph?.scrollIntoView({ behavior: "instant", block: "end" })
    }
  }

  #observeReadingProgress() {
    this.observer = new IntersectionObserver(this.#intersectionChange, { threshold: 0.5 })
    this.paragraphs.forEach(p => this.observer.observe(p))
  }

  #intersectionChange = (entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        this.visibleParagraphs.add(entry.target)
      } else {
        this.visibleParagraphs.delete(entry.target)
      }
    })

    this.#updateLastReadParagraph()
    this.#storeProgress()
  }

  #updateLastReadParagraph() {
    const sortedVisibleParagraphs = Array.from(this.visibleParagraphs).sort((p1, p2) => {
      return this.paragraphs.indexOf(p1) - this.paragraphs.indexOf(p2)
    })

    if (sortedVisibleParagraphs.length > 0) {
      const lastVisibleParagraph = sortedVisibleParagraphs[sortedVisibleParagraphs.length - 1]
      this.lastReadParagraphIndex = this.paragraphs.indexOf(lastVisibleParagraph)
    }
  }

  #storeProgress() {
    storeReadingProgress(this.bookIdValue, this.leafIdValue, this.lastReadParagraphIndex)
  }
}
