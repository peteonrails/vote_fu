import { Controller } from "@hotwired/stimulus"

/**
 * Reactions Stimulus Controller
 *
 * Handles emoji reaction interactions with optimistic updates.
 */
export default class extends Controller {
  static targets = ["reaction", "addButton", "picker"]

  static values = {
    voteableType: String,
    voteableId: Number,
    allowMultiple: { type: Boolean, default: true }
  }

  connect() {
    this.pickerVisible = false
  }

  /**
   * Toggle a reaction
   */
  toggle(event) {
    const form = event.target.closest("form")
    const scope = form.querySelector("[name='scope']")?.value
    const button = form.querySelector("button")

    if (!button) return

    const isActive = button.classList.contains("vote-fu-reaction--active")

    // Optimistic update
    if (isActive) {
      this.removeReaction(button, scope)
    } else {
      this.addReaction(button, scope)
    }
  }

  /**
   * Add reaction (optimistic)
   */
  addReaction(button, scope) {
    button.classList.add("vote-fu-reaction--active")
    button.closest(".vote-fu-reaction-wrapper")?.classList.add("vote-fu-reaction-wrapper--active")

    // Update count
    const countEl = button.querySelector(".vote-fu-reaction-count")
    if (countEl) {
      const count = parseInt(countEl.textContent, 10) || 0
      countEl.textContent = count + 1
    }
  }

  /**
   * Remove reaction (optimistic)
   */
  removeReaction(button, scope) {
    button.classList.remove("vote-fu-reaction--active")
    button.closest(".vote-fu-reaction-wrapper")?.classList.remove("vote-fu-reaction-wrapper--active")

    // Update count
    const countEl = button.querySelector(".vote-fu-reaction-count")
    if (countEl) {
      const count = parseInt(countEl.textContent, 10) || 0
      countEl.textContent = Math.max(0, count - 1)
    }
  }

  /**
   * Show reaction picker
   */
  showPicker(event) {
    // Emit custom event for apps to handle their own picker UI
    this.dispatch("showPicker", {
      detail: {
        voteableType: this.voteableTypeValue,
        voteableId: this.voteableIdValue,
        target: event.target
      }
    })
  }

  /**
   * Hide reaction picker
   */
  hidePicker() {
    this.pickerVisible = false
    this.dispatch("hidePicker")
  }
}
