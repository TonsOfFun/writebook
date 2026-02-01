import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileField", "urlField", "textField", "typeOption"]

  connect() {
    this.updateFieldVisibility()
  }

  typeChanged() {
    this.updateFieldVisibility()
  }

  updateFieldVisibility() {
    const selectedType = this.element.querySelector('input[name="source[source_type]"]:checked')?.value

    this.toggleField(this.fileFieldTarget, ["pdf", "image"].includes(selectedType))
    this.toggleField(this.urlFieldTarget, selectedType === "url")
    this.toggleField(this.textFieldTarget, selectedType === "text")

    // Update radio card styles
    this.typeOptionTargets.forEach(option => {
      const isSelected = option.dataset.type === selectedType
      option.classList.toggle("radio-card--selected", isSelected)
    })
  }

  toggleField(field, show) {
    if (field) {
      field.style.display = show ? "block" : "none"
      const input = field.querySelector("input, textarea")
      if (input) {
        input.required = show
      }
    }
  }
}
