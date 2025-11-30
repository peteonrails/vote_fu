# frozen_string_literal: true

# VoteFu Configuration
#
# For more information, see: https://github.com/peteonrails/vote_fu

VoteFu.configure do |config|
  # Allow voters to change their vote after casting
  # Default: true
  # config.allow_recast = true

  # Allow multiple votes from the same voter on the same item
  # Default: false
  # config.allow_duplicate_votes = false

  # Allow a model to vote on itself (if it's both voter and voteable)
  # Default: false
  # config.allow_self_vote = false

  # Automatically maintain counter cache columns on voteables
  # Requires: votes_count, votes_total, upvotes_count, downvotes_count columns
  # Default: true
  # config.counter_cache = true

  # Broadcast vote changes via Turbo Streams
  # Default: true
  # config.turbo_broadcasts = true

  # Use ActionCable for real-time updates
  # Default: true
  # config.action_cable = true

  # Default ranking algorithm for voteables
  # Options: :wilson_score, :reddit_hot, :hacker_news, :simple
  # Default: :wilson_score
  # config.default_ranking = :wilson_score

  # Gravity parameter for Reddit Hot and Hacker News algorithms
  # Higher values = faster decay
  # Default: 1.8
  # config.hot_ranking_gravity = 1.8
end
