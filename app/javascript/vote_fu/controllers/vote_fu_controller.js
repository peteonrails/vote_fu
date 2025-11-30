import { Controller } from "@hotwired/stimulus"

/**
 * VoteFu Stimulus Controller
 *
 * Provides optimistic UI updates for voting actions.
 * Works with Turbo Streams for server reconciliation.
 *
 * @example
 * <div data-controller="vote-fu"
 *      data-vote-fu-voteable-type-value="Post"
 *      data-vote-fu-voteable-id-value="123"
 *      data-vote-fu-scope-value=""
 *      data-vote-fu-voted-value="false"
 *      data-vote-fu-direction-value="">
 *   ...
 * </div>
 */
export default class extends Controller {
  static targets = ["upvoteBtn", "downvoteBtn", "likeBtn", "count"]

  static values = {
    voteableType: String,
    voteableId: Number,
    scope: String,
    voted: Boolean,
    direction: String
  }

  connect() {
    this.originalCount = this.countTarget?.textContent?.trim()
  }

  /**
   * Handle vote form submission with optimistic update
   */
  vote(event) {
    const form = event.target.closest("form")
    const direction = form.querySelector("[name='direction']")?.value

    // Optimistic update
    this.updateUI(direction)
  }

  /**
   * Update UI optimistically based on vote direction
   */
  updateUI(direction) {
    const wasVoted = this.votedValue
    const previousDirection = this.directionValue

    // Toggle logic
    if (wasVoted && previousDirection === direction) {
      // Removing vote
      this.votedValue = false
      this.directionValue = ""
      this.updateCount(-this.voteIncrement(previousDirection))
      this.clearActiveStates()
    } else if (wasVoted && previousDirection !== direction) {
      // Changing vote direction
      this.directionValue = direction
      this.updateCount(
        this.voteIncrement(direction) - this.voteIncrement(previousDirection)
      )
      this.setActiveState(direction)
    } else {
      // New vote
      this.votedValue = true
      this.directionValue = direction
      this.updateCount(this.voteIncrement(direction))
      this.setActiveState(direction)
    }
  }

  /**
   * Get vote increment for a direction
   */
  voteIncrement(direction) {
    return direction === "up" ? 1 : -1
  }

  /**
   * Update the vote count display
   */
  updateCount(delta) {
    if (!this.hasCountTarget) return

    const currentCount = parseInt(this.countTarget.textContent, 10) || 0
    const newCount = currentCount + delta
    this.countTarget.textContent = newCount

    // Add animation class
    this.countTarget.classList.add("vote-fu-count-updated")
    setTimeout(() => {
      this.countTarget.classList.remove("vote-fu-count-updated")
    }, 300)
  }

  /**
   * Clear all active states from buttons
   */
  clearActiveStates() {
    if (this.hasUpvoteBtnTarget) {
      this.upvoteBtnTarget.classList.remove("vote-fu-active")
    }
    if (this.hasDownvoteBtnTarget) {
      this.downvoteBtnTarget.classList.remove("vote-fu-active")
    }
    if (this.hasLikeBtnTarget) {
      this.likeBtnTarget.classList.remove("vote-fu-active")
    }
    this.element.classList.remove("vote-fu-voted-up", "vote-fu-voted-down", "vote-fu-liked")
  }

  /**
   * Set active state for a direction
   */
  setActiveState(direction) {
    this.clearActiveStates()

    if (direction === "up") {
      if (this.hasUpvoteBtnTarget) {
        this.upvoteBtnTarget.classList.add("vote-fu-active")
      }
      if (this.hasLikeBtnTarget) {
        this.likeBtnTarget.classList.add("vote-fu-active")
      }
      this.element.classList.add("vote-fu-voted-up", "vote-fu-liked")
    } else if (direction === "down") {
      if (this.hasDownvoteBtnTarget) {
        this.downvoteBtnTarget.classList.add("vote-fu-active")
      }
      this.element.classList.add("vote-fu-voted-down")
    }
  }

  /**
   * Reset to server state (called on Turbo Stream failure)
   */
  reset() {
    if (this.hasCountTarget && this.originalCount) {
      this.countTarget.textContent = this.originalCount
    }
    this.clearActiveStates()
    this.votedValue = false
    this.directionValue = ""
  }
}
