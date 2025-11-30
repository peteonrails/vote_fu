# frozen_string_literal: true

module VoteFu
  class Vote < ApplicationRecord
    self.table_name = "vote_fu_votes"

    # Associations
    belongs_to :voter, polymorphic: true
    belongs_to :voteable, polymorphic: true

    # Validations
    validates :value, presence: true, numericality: { only_integer: true }
    validates :voter_id, uniqueness: {
      scope: %i[voter_type voteable_id voteable_type scope],
      message: "has already voted on this item"
    }, unless: :allow_duplicate_votes?

    # Scopes
    scope :up, -> { where(value: 1..) }
    scope :down, -> { where(value: ..0) }
    scope :with_scope, ->(s) { s.present? ? where(scope: s) : where(scope: nil) }
    scope :for_voter, ->(voter) { where(voter: voter) }
    scope :for_voteable, ->(voteable) { where(voteable: voteable) }
    scope :recent, ->(since = 2.weeks.ago) { where(created_at: since..) }
    scope :chronological, -> { order(created_at: :desc) }
    scope :by_value, -> { order(value: :desc) }

    # Callbacks for counter cache
    after_create :increment_voteable_counters
    after_update :update_voteable_counters, if: :saved_change_to_value?
    after_destroy :decrement_voteable_counters

    # Callbacks for broadcasts
    after_commit :broadcast_vote_change, if: :broadcasts_enabled?

    # Instance methods
    def up?
      value.positive?
    end

    def down?
      value.negative?
    end

    def direction
      return :up if up?
      return :down if down?

      :neutral
    end

    private

    def allow_duplicate_votes?
      VoteFu.configuration.allow_duplicate_votes
    end

    def broadcasts_enabled?
      VoteFu.configuration.turbo_broadcasts && defined?(Turbo::StreamsChannel)
    end

    def increment_voteable_counters
      return unless VoteFu.configuration.counter_cache
      return unless voteable.respond_to?(:increment_vote_counters)

      voteable.increment_vote_counters(value)
    end

    def update_voteable_counters
      return unless VoteFu.configuration.counter_cache
      return unless voteable.respond_to?(:update_vote_counters)

      old_value = value_before_last_save
      voteable.update_vote_counters(old_value, value)
    end

    def decrement_voteable_counters
      return unless VoteFu.configuration.counter_cache
      return unless voteable.respond_to?(:decrement_vote_counters)

      voteable.decrement_vote_counters(value)
    end

    def broadcast_vote_change
      return unless voteable.respond_to?(:broadcast_vote_update)

      voteable.broadcast_vote_update
    end
  end
end
