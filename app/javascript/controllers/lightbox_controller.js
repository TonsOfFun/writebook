import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "image", "dialog", "zoomedImage" ]

  open(event) {
    this.dialogTarget.showModal()
    this.#set(event.target.closest("a"))
  }

  reset() {
    this.zoomedImageTarget.src = ""
  }

  #set(target) {
    this.zoomedImageTarget.src = target.href
  }
}
