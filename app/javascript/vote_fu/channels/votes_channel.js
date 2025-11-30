import consumer from "./consumer"

/**
 * VoteFu ActionCable Channel
 *
 * Subscribe to real-time vote updates for a voteable.
 *
 * @example
 * import { subscribeToVotes } from "vote_fu/channels/votes_channel"
 *
 * const subscription = subscribeToVotes({
 *   voteableType: "Post",
 *   voteableId: 123,
 *   scope: null,
 *   onUpdate: (data) => {
 *     console.log("Vote updated:", data)
 *   }
 * })
 *
 * // Later: subscription.unsubscribe()
 */
export function subscribeToVotes({ voteableType, voteableId, scope = null, onUpdate }) {
  return consumer.subscriptions.create(
    {
      channel: "VoteFu::VotesChannel",
      voteable_type: voteableType,
      voteable_id: voteableId,
      scope: scope
    },
    {
      connected() {
        console.log(`VoteFu: Connected to ${voteableType}#${voteableId}`)
      },

      disconnected() {
        console.log(`VoteFu: Disconnected from ${voteableType}#${voteableId}`)
      },

      received(data) {
        if (data.type === "vote_update") {
          // Update DOM elements automatically
          this.updateVoteWidget(data)

          // Call custom callback
          if (onUpdate) {
            onUpdate(data)
          }
        }
      },

      updateVoteWidget(data) {
        const { voteable_type, voteable_id, scope, stats } = data
        const scopeSuffix = scope ? `_${scope}` : ""
        const baseId = `vote_fu_${voteable_type.toLowerCase()}_${voteable_id}${scopeSuffix}`

        // Update count display
        const countEl = document.getElementById(`${baseId}_count`)
        if (countEl) {
          countEl.textContent = stats.plusminus
          countEl.classList.add("vote-fu-count-updated")
          setTimeout(() => countEl.classList.remove("vote-fu-count-updated"), 300)
        }

        // Dispatch custom event for advanced handling
        document.dispatchEvent(new CustomEvent("vote-fu:updated", {
          detail: data,
          bubbles: true
        }))
      }
    }
  )
}

/**
 * Auto-subscribe to all vote widgets on the page
 *
 * Call this on page load to automatically subscribe to all voteable elements.
 */
export function autoSubscribe() {
  const widgets = document.querySelectorAll("[data-vote-fu-subscribe]")

  widgets.forEach((widget) => {
    const voteableType = widget.dataset.voteFuVoteableType
    const voteableId = widget.dataset.voteFuVoteableId
    const scope = widget.dataset.voteFuScope || null

    if (voteableType && voteableId) {
      subscribeToVotes({ voteableType, voteableId, scope })
    }
  })
}

export default { subscribeToVotes, autoSubscribe }
