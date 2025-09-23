import { Controller } from "@hotwired/stimulus"
import { readCookie, setCookie } from "helpers/cookie_helpers"

export default class extends Controller {
  static values = { targetUrl: String }
  static classes = [ "editing" ]
  static outlets = [ "autosave" ]

  connect() {
    document.body.classList.toggle(this.editingClass, this.#savedCheckedState)
  }

  async change({ target: { checked } }) {
    if (!checked) {
      await this.#submitAutosaveControllers()
    }

    setCookie("edit_mode", checked)
    Turbo.visit(this.targetUrlValue)
  }


  async #submitAutosaveControllers() {
    for (const autosave of this.autosaveOutlets) {
      await autosave.submit()
    }
  }

  get #savedCheckedState() {
    return readCookie("edit_mode") === "true"
  }
}
