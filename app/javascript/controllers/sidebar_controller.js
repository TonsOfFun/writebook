import { Controller } from "@hotwired/stimulus"
import { readCookie, setCookie } from "helpers/cookie_helpers"

export default class extends Controller {
  static targets = [ "toggle" ]

  connect() {
    this.toggleTarget.checked = this.#savedSidebarOpenState
  }

  toggle() {
    this.#saveViewPref()
  }

  #saveViewPref() {
    const isChecked = this.toggleTarget.checked
    setCookie("sidebar-open", isChecked.toString())
  }

  get #savedSidebarOpenState() {
    return readCookie("sidebar-open") === "true"
  }
}
