import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { defaultImage: String }
  static targets = [ "image", "input", "button" ]

  previewImage() {
    const file = this.inputTarget.files[0]

    if (file) {
      this.imageTarget.src = URL.createObjectURL(this.inputTarget.files[0]);
      this.imageTarget.onload = () => { URL.revokeObjectURL(this.imageTarget.src) }
    }
  }

  clear() {
    this.imageTarget.src = this.defaultImageValue
    this.buttonTarget.style.visibility = "hidden"
  }
}
