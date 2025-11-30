# frozen_string_literal: true

module VoteFu
  class Configuration
    # Can voters change their vote after casting?
    attr_accessor :allow_recast

    # Can voters cast multiple votes on the same item?
    attr_accessor :allow_duplicate_votes

    # Can a model vote on itself?
    attr_accessor :allow_self_vote

    # Automatically maintain counter cache columns?
    attr_accessor :counter_cache

    # Broadcast vote changes via Turbo Streams?
    attr_accessor :turbo_broadcasts

    # Use ActionCable for real-time updates?
    attr_accessor :action_cable

    # Default ranking algorithm (:wilson_score, :reddit_hot, :hacker_news, :simple)
    attr_accessor :default_ranking

    # Gravity parameter for hot ranking algorithms
    attr_accessor :hot_ranking_gravity

    def initialize
      @allow_recast = true
      @allow_duplicate_votes = false
      @allow_self_vote = false
      @counter_cache = true
      @turbo_broadcasts = true
      @action_cable = true
      @default_ranking = :wilson_score
      @hot_ranking_gravity = 1.8
    end

    def to_h
      {
        allow_recast: allow_recast,
        allow_duplicate_votes: allow_duplicate_votes,
        allow_self_vote: allow_self_vote,
        counter_cache: counter_cache,
        turbo_broadcasts: turbo_broadcasts,
        action_cable: action_cable,
        default_ranking: default_ranking,
        hot_ranking_gravity: hot_ranking_gravity
      }
    end
  end
end
