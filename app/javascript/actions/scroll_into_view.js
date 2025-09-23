import { Turbo } from "@hotwired/turbo-rails"

Turbo.StreamActions.scroll_into_view = function() {
  const animation = this.getAttribute("animation")
  const element = this.targetElements[0]

  element.scrollIntoView({ behavior: "smooth", block: "center" })

  if (animation) {
    element.addEventListener("animationend", () => {
      element.classList.remove(animation)
    }, { once: true })

    element.classList.add(animation)
  }
}
