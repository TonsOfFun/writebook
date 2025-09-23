import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

const Direction = {
  BEFORE: -1,
  AFTER: 1
}

const NEW_ITEM_ID = "dragged_item"
const NEW_ITEM_DATA_TYPE = "x-writebook/create"
const MOVE_ITEM_DATA_TYPE = "x-writebook/move"
const ITEM_SELECTOR = "[data-arrangement-target=item]"

export default class extends Controller {
  static targets = [ "container", "list", "item", "layer", "dragImage" ]
  static classes = [ "cursor", "selected", "placeholder", "addingMode", "moveMode" ]
  static values = { url: String }

  #cursorPosition
  #dragItem
  #wasDropped
  #originalOrder
  #selection
  #moveMode = false
  #arrangeMode = false


  // Actions - selection state

  click(event) {
    if (!this.#arrangeMode) { return }

    const target = event.target.closest(ITEM_SELECTOR)
    this.#setSelection(target, event.shiftKey)
  }

  setArrangeMode(event) {
    this.#arrangeMode = event.target.checked

    for (const item of this.itemTargets) {
      item.setAttribute("draggable", this.#arrangeMode)
    }
    this.#resetSelection()
  }


  // Actions - keyboard

  moveBefore(event) {
    if (!this.#arrangeMode) { return }

    event.preventDefault()

    if (this.#moveMode) {
      this.#moveSelection(Direction.BEFORE)
    } else {
      const newPosition = this.#cursorPosition === undefined ? this.itemTargets.length - 1 : Math.max(this.#cursorPosition - 1, 0)
      this.#setCursor(newPosition, event.shiftKey)
    }
  }

  moveAfter(event) {
    if (!this.#arrangeMode) { return }

    event.preventDefault()

    if (this.#moveMode) {
      this.#moveSelection(Direction.AFTER)
    } else {
      const newPosition = this.#cursorPosition === undefined ? 0 : Math.min(this.#cursorPosition + 1, this.itemTargets.length - 1)
      this.#setCursor(newPosition, event.shiftKey)
    }
  }

  toggleMoveMode(event) {
    if (!this.#arrangeMode) { return }

    event.preventDefault()

    if (this.#moveMode) {
      this.applyMoveMode(event)
    } else {
      this.#moveMode = true
      this.#saveOriginalOrder()
    }

    this.#renderSelection()
  }

  applyMoveMode(event) {
    if (!this.#arrangeMode) { return }

    event.preventDefault()

    this.#moveMode = false
    this.#renderSelection()
    this.#submitMove()
  }

  cancelMoveMode(event) {
    if (!this.#arrangeMode) { return }

    event.preventDefault()

    if (this.#moveMode) {
      this.#restoreOriginalOrder()
      this.#moveMode = false
    }

    this.#resetSelection()
  }


  // Actions - drag & drop

  dragStartCreate(event) {
    this.#saveOriginalOrder()

    const entry = document.createElement("li")
    entry.id = NEW_ITEM_ID
    entry.innerHTML = "&nbsp;"
    entry.dataset.arrangementTarget = "item"
    this.listTarget.prepend(entry)

    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData(NEW_ITEM_DATA_TYPE, event.params.url)

    this.#wasDropped = false
    this.#dragItem = entry
    this.#setSelection(entry, false)

    this.containerTarget.classList.add(this.addingModeClass)
    this.#enableDraggingLayer()
  }

  dragEndCreate() {
    if (!this.#wasDropped) {
      this.#dragItem.remove()
      this.#restoreOriginalOrder()
      this.#selection = undefined
      this.#renderSelection()
    }

    this.containerTarget.classList.remove(this.addingModeClass)
    this.#disableDraggingLayer()
  }

  dragStart(event) {
    this.#wasDropped = false
    this.#dragItem = event.target
    this.#saveOriginalOrder()

    event.dataTransfer.dropEffect = "move"
    event.dataTransfer.setData(MOVE_ITEM_DATA_TYPE, event.target)

    if (!this.#targetIsSelected(event.target)) {
      this.#setSelection(event.target, false)
    }

    if (this.#selectionSize > 1) {
      this.dragImageTarget.textContent = `${this.#selectionSize} items`
      event.dataTransfer.setDragImage(this.dragImageTarget, 0, 0)
    }

    this.#enableDraggingLayer()
  }

  drop(event) {
    this.#wasDropped = true

    const createURL = event.dataTransfer.getData(NEW_ITEM_DATA_TYPE)
    if (createURL) {
      this.#submitCreate(createURL)
    } else {
      if (this.#arrangeMode) {
        this.#submitMove()
      }
    }
  }

  dragEnd() {
    if (!this.#wasDropped) {
      this.#restoreOriginalOrder()
      this.#selection = undefined
      this.#renderSelection()
    }

    this.#disableDraggingLayer()
  }

  dragOver(event) {
    if (this.itemTargets.includes(event.target) && !this.#targetIsSelected(event.target)) {
      const offset = this.itemTargets.indexOf(this.#dragItem) - this.itemTargets.indexOf(event.target)
      const isBefore = offset < 0

      this.#keepingSelection(() => {
        if (isBefore) {
          event.target.after(...this.#selectedItems)
        } else {
          event.target.before(...this.#selectedItems)
        }
      })
      this.#updateLayer()
      this.#renderSelection()
    }
  }


  // Internal

  #setCursor(index, expandSelection) {
    this.#cursorPosition = index
    this.itemTargets[this.#cursorPosition].scrollIntoView({ block: 'nearest', inline: 'nearest' })
    this.#setSelection(this.itemTargets[index], expandSelection)
  }

  #setSelection(target, expandSelection) {
    const idx = this.itemTargets.indexOf(target)

    if (expandSelection && this.#selection) {
      this.#selection = [
        Math.min(idx, this.#selectionStart),
        Math.max(idx, this.#selectionEnd),
      ]
    } else {
      this.#selection = [ idx, idx ]
    }

    this.#renderSelection()
  }

  #renderSelection() {
    for (const [ index, item ] of this.itemTargets.entries()) {
      item.classList.toggle(this.selectedClass, index >= this.#selectionStart && index <= this.#selectionEnd)
      item.classList.toggle(this.cursorClass, index === this.#cursorPosition)
    }
    this.containerTarget.classList.toggle(this.moveModeClass, this.#moveMode)
  }

  #moveSelection(direction) {
    this.#keepingSelection(() => {
      if (direction === Direction.BEFORE && this.#selectionStart > 0) {
        this.itemTargets[this.#selectionEnd].after(this.itemTargets[this.#selectionStart - 1])
        this.#cursorPosition--
      }
      if (direction === Direction.AFTER && this.#selectionEnd < this.itemTargets.length - 1) {
        this.itemTargets[this.#selectionStart].before(this.itemTargets[this.#selectionEnd + 1])
        this.#cursorPosition++
      }
    })
    this.#renderSelection()
  }

  #enableDraggingLayer() {
    this.#buildLayer()

    setTimeout(() => {
      this.containerTarget.style.opacity = "0"
    }, 0)
  }

  #disableDraggingLayer() {
    this.containerTarget.style.opacity = "1"
    this.#clearLayer()
  }

  #buildLayer() {
    const fragment = document.createDocumentFragment()

    for (const [ index, item ] of this.itemTargets.entries()) {
      const selected = index >= this.#selectionStart && index <= this.#selectionEnd
      const clone = selected ? this.#makePlaceholder() : item.cloneNode(true)

      clone.style.position = "absolute"
      clone.style.pointerEvents = "none"
      clone.style.transition = "top 160ms, left 160ms"

      fragment.append(clone)
      item.clone = clone
    }

    this.layerTarget.append(fragment)
    this.#updateLayer()
  }

  #updateLayer() {
    const updates = []

    for (const item of this.itemTargets) {
      if (item.clone) {
        updates.push({ el: item.clone, rect: this.#getElementRect(item) })
      }
    }

    for (const { el, rect } of updates) {
      this.#setElementRect(el, rect)
    }
  }

  #clearLayer() {
    this.layerTarget.innerHTML = ""
  }

  #getElementRect(element) {
    const rect = element.getBoundingClientRect()
    const parent = element.closest(".position-relative").getBoundingClientRect()

    return {
      top: rect.top - parent.top,
      left: rect.left - parent.left,
      bottom: rect.bottom - parent.bottom,
      right: rect.right - parent.right,
      width: rect.width,
      height: rect.height
    };
  }

  #setElementRect(element, rect) {
    element.style.position = 'absolute'
    element.style.left = `${rect.left}px`
    element.style.top = `${rect.top}px`
    element.style.width = `${rect.width}px`
    element.style.height = `${rect.height}px`
  }

  #makePlaceholder() {
    const node = document.createElement("div")
    node.classList.add(this.placeholderClass)
    return node
  }

  #targetIsSelected(target) {
    const idx = this.itemTargets.indexOf(target)
    return idx >= this.#selectionStart && idx <= this.#selectionEnd
  }

  #keepingSelection(fn) {
    const first = this.itemTargets[this.#selectionStart]
    const last = this.itemTargets[this.#selectionEnd]
    fn()
    this.#selection = [ this.itemTargets.indexOf(first), this.itemTargets.indexOf(last) ]
  }

  #resetSelection() {
    this.#selection = undefined
    this.#cursorPosition = undefined
    this.#renderSelection()
  }

  #submitMove() {
    const position = this.#selection[0]
    const ids = this.itemTargets
      .slice(this.#selection[0], this.#selection[1] + 1)
      .map((item) => item.dataset.id)

    const body = new FormData()
    body.append("position", position)
    ids.forEach((id) => body.append("id[]", id))

    post(this.urlValue, { body })
  }

  #submitCreate(url) {
    const position = this.#selection[0]

    const body = new FormData()
    body.append("position", position)

    post(url, { body, responseKind: "turbo-stream" })
  }

  #saveOriginalOrder() {
    this.#originalOrder = [ ...this.itemTargets ]
  }

  #restoreOriginalOrder() {
    this.listTarget.append(...this.#originalOrder)
    this.#originalOrder = undefined
  }

  get #selectionStart() {
    if (this.#selection) {
      return this.#selection[0]
    }
  }

  get #selectionEnd() {
    if (this.#selection) {
      return this.#selection[1]
    }
  }

  get #selectionSize() {
    if (this.#selection) {
      return this.#selectionEnd - this.#selectionStart + 1
    }
    return 0
  }

  get #selectedItems() {
    return this.itemTargets.slice(this.#selectionStart, this.#selectionEnd + 1)
  }
}
