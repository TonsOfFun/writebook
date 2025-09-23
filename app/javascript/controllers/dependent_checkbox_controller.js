import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dependant", "dependee" ]

  input({target}) {
    if (target === this.dependantTarget && target.checked) {
      this.dependeeTarget.checked = true
    }

    if (target === this.dependeeTarget && !target.checked) {
      this.dependantTarget.checked = false
    }
  }
}
