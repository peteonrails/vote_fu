# frozen_string_literal: true

# Migration for test tables
class CreateTestTables < ActiveRecord::Migration[7.2]
  def self.up
    create_table :vote_fu_votes, force: true do |t|
      t.references :voter, polymorphic: true, null: false
      t.references :voteable, polymorphic: true, null: false
      t.integer :value, null: false, default: 1
      t.string :scope
      t.timestamps
    end

    add_index :vote_fu_votes,
              %i[voter_type voter_id voteable_type voteable_id scope],
              unique: true,
              name: "idx_vote_fu_unique_vote"

    create_table :users, force: true do |t|
      t.string :name
      t.timestamps
    end

    create_table :posts, force: true do |t|
      t.string :title
      t.references :user
      t.integer :votes_count, default: 0
      t.integer :votes_total, default: 0
      t.integer :upvotes_count, default: 0
      t.integer :downvotes_count, default: 0
      t.timestamps
    end

    create_table :comments, force: true do |t|
      t.text :body
      t.references :user
      t.references :post
      t.timestamps
    end
  end

  def self.down
    drop_table :comments
    drop_table :posts
    drop_table :users
    drop_table :vote_fu_votes
  end
end

# VoteFu Vote model (simplified for testing)
module VoteFu
  class Vote < ActiveRecord::Base
    self.table_name = "vote_fu_votes"

    belongs_to :voter, polymorphic: true
    belongs_to :voteable, polymorphic: true

    validates :value, presence: true, numericality: { only_integer: true }
    validates :voter_id, uniqueness: {
      scope: %i[voter_type voteable_id voteable_type scope],
      message: "has already voted on this item"
    }, unless: :allow_duplicate_votes?

    scope :up, -> { where(value: 1..) }
    scope :down, -> { where(value: ..0) }
    scope :with_scope, ->(s) { s.present? ? where(scope: s) : where(scope: nil) }
    scope :for_voter, ->(voter) { where(voter: voter) }
    scope :for_voteable, ->(voteable) { where(voteable: voteable) }
    scope :recent, ->(since = 2.weeks.ago) { where(created_at: since..) }
    scope :chronological, -> { order(created_at: :desc) }
    scope :by_value, -> { order(value: :desc) }

    after_create :increment_voteable_counters
    after_update :update_voteable_counters, if: :saved_change_to_value?
    after_destroy :decrement_voteable_counters

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
  end
end

# Test models
class User < ActiveRecord::Base
  has_many :posts
  has_many :comments

  acts_as_voter
  votes_on :posts, :comments
  has_karma :posts
end

class Post < ActiveRecord::Base
  belongs_to :user, optional: true
  has_many :comments

  acts_as_voteable
end

class Comment < ActiveRecord::Base
  belongs_to :user, optional: true
  belongs_to :post, optional: true

  acts_as_voteable
end
