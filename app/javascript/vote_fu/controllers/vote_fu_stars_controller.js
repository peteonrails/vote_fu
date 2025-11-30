import { Controller } from "@hotwired/stimulus"

/**
 * Star Rating Stimulus Controller
 *
 * Handles star rating interactions with optimistic updates.
 */
export default class extends Controller {
  static targets = ["star"]

  static values = {
    voteableType: String,
    voteableId: Number,
    scope: String,
    currentRating: Number,
    maxStars: { type: Number, default: 5 }
  }

  connect() {
    this.originalRating = this.currentRatingValue
    this.hoverRating = 0
  }

  /**
   * Handle star hover
   */
  hover(event) {
    const starValue = parseInt(event.target.dataset.starValue, 10)
    this.hoverRating = starValue
    this.updateStarDisplay(starValue)
  }

  /**
   * Handle mouse leave
   */
  leave() {
    this.hoverRating = 0
    this.updateStarDisplay(this.currentRatingValue)
  }

  /**
   * Handle rating submission
   */
  rate(event) {
    const form = event.target.closest("form")
    const starValue = parseInt(form.querySelector("[name='value']").value, 10)

    // Optimistic update
    this.currentRatingValue = starValue
    this.updateStarDisplay(starValue)
  }

  /**
   * Update star visual display
   */
  updateStarDisplay(rating) {
    this.starTargets.forEach((star) => {
      const starValue = parseInt(star.dataset.starValue, 10)
      const isFilled = starValue <= rating

      star.classList.toggle("vote-fu-star-filled", isFilled)

      // Update star character if using text content
      if (star.tagName === "BUTTON") {
        star.textContent = isFilled ? "★" : "☆"
      }
    })
  }

  /**
   * Reset to original state (on error)
   */
  reset() {
    this.currentRatingValue = this.originalRating
    this.updateStarDisplay(this.originalRating)
  }
}
