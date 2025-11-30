# frozen_string_literal: true

require "active_support/concern"

module VoteFu
  module Concerns
    module Voteable
      extend ActiveSupport::Concern

      class_methods do
        # Configure a model to receive votes
        #
        # @example Basic usage
        #   class Post < ApplicationRecord
        #     acts_as_voteable
        #   end
        #
        # @example With options
        #   class Post < ApplicationRecord
        #     acts_as_voteable counter_cache: true, broadcasts: true
        #   end
        #
        # @param options [Hash] Configuration options
        # @option options [Boolean] :counter_cache (true) Maintain vote count columns
        # @option options [Boolean] :broadcasts (true) Broadcast changes via Turbo
        # @option options [Array<Symbol>] :scopes (nil) Allowed voting scopes
        def acts_as_voteable(**options)
          class_attribute :vote_fu_voteable_options, default: {
            counter_cache: VoteFu.configuration.counter_cache,
            broadcasts: VoteFu.configuration.turbo_broadcasts,
            scopes: nil
          }.merge(options)

          has_many :received_votes,
                   class_name: "VoteFu::Vote",
                   as: :voteable,
                   dependent: :destroy,
                   inverse_of: :voteable

          include VoteFu::Concerns::Voteable::InstanceMethods
          extend VoteFu::Concerns::Voteable::ClassMethods
        end

        # Alternative DSL: declare which models can vote on this one
        #
        # @example
        #   class Post < ApplicationRecord
        #     voteable_by :users, :admins
        #   end
        def voteable_by(*voter_classes, **options)
          acts_as_voteable(**options)

          class_attribute :vote_fu_allowed_voters, default: voter_classes.map(&:to_s).map(&:classify)
        end
      end

      module ClassMethods
        # Order by total vote value (sum of all vote values)
        def by_votes(direction = :desc)
          left_joins(:received_votes)
            .group(:id)
            .order(Arel.sql("COALESCE(SUM(vote_fu_votes.value), 0) #{direction.to_s.upcase}"))
        end

        # Order by vote count
        def by_vote_count(direction = :desc)
          left_joins(:received_votes)
            .group(:id)
            .order(Arel.sql("COUNT(vote_fu_votes.id) #{direction.to_s.upcase}"))
        end

        # Items with positive net votes
        def with_positive_score
          left_joins(:received_votes)
            .group(:id)
            .having("COALESCE(SUM(vote_fu_votes.value), 0) > 0")
        end

        # Items with any votes
        def with_votes
          joins(:received_votes).distinct
        end

        # Items without any votes
        def without_votes
          left_joins(:received_votes)
            .where(vote_fu_votes: { id: nil })
        end

        # Trending items (most votes in time period)
        def trending(since: 24.hours.ago)
          joins(:received_votes)
            .where(vote_fu_votes: { created_at: since.. })
            .group(:id)
            .order(Arel.sql("COUNT(vote_fu_votes.id) DESC"))
        end
      end

      module InstanceMethods
        # Count of upvotes
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Integer]
        def votes_for(scope: nil)
          received_votes.with_scope(scope).up.count
        end

        # Count of downvotes
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Integer]
        def votes_against(scope: nil)
          received_votes.with_scope(scope).down.count
        end

        # Total number of votes
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Integer]
        def votes_count(scope: nil)
          received_votes.with_scope(scope).count
        end

        # Sum of all vote values
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Integer]
        def votes_total(scope: nil)
          received_votes.with_scope(scope).sum(:value)
        end

        # Net score (upvotes minus downvotes)
        # Uses counter cache if available
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Integer]
        def plusminus(scope: nil)
          if has_attribute?(:votes_total) && scope.nil?
            read_attribute(:votes_total) || 0
          else
            votes_for(scope: scope) - votes_against(scope: scope)
          end
        end

        # Percentage of upvotes
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Float] 0.0 to 100.0
        def percent_for(scope: nil)
          total = votes_count(scope: scope)
          return 0.0 if total.zero?

          (votes_for(scope: scope).to_f / total * 100).round(1)
        end

        # Percentage of downvotes
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Float] 0.0 to 100.0
        def percent_against(scope: nil)
          total = votes_count(scope: scope)
          return 0.0 if total.zero?

          (votes_against(scope: scope).to_f / total * 100).round(1)
        end

        # Check if a voter has voted on this item
        # @param voter [ActiveRecord::Base] The voter to check
        # @param direction [Symbol, nil] :up, :down, or nil for any
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Boolean]
        def voted_by?(voter, direction: nil, scope: nil)
          vote = received_votes.find_by(voter: voter, scope: scope)
          return false unless vote

          case direction
          when nil then true
          when :up, :positive then vote.up?
          when :down, :negative then vote.down?
          else false
          end
        end

        # Get all voters who voted on this item
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Array<ActiveRecord::Base>]
        def voters(scope: nil)
          received_votes.with_scope(scope).includes(:voter).map(&:voter).uniq
        end

        # Get voters who upvoted
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Array<ActiveRecord::Base>]
        def voters_for(scope: nil)
          received_votes.with_scope(scope).up.includes(:voter).map(&:voter).uniq
        end

        # Get voters who downvoted
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Array<ActiveRecord::Base>]
        def voters_against(scope: nil)
          received_votes.with_scope(scope).down.includes(:voter).map(&:voter).uniq
        end

        # Wilson Score Lower Bound
        # @param confidence [Float] Confidence level (0.0 to 1.0)
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Float] Score from 0.0 to 1.0
        def wilson_score(confidence: 0.95, scope: nil)
          VoteFu::Algorithms::WilsonScore.call(self, confidence: confidence, scope: scope)
        end

        # Reddit Hot ranking score
        # @param gravity [Float] Gravity parameter
        # @return [Float]
        def hot_score(gravity: nil)
          gravity ||= VoteFu.configuration.hot_ranking_gravity
          VoteFu::Algorithms::RedditHot.call(self, gravity: gravity)
        end

        # Counter cache methods
        def increment_vote_counters(value)
          return unless vote_fu_voteable_options[:counter_cache]

          updates = {}
          updates[:votes_count] = 1 if has_attribute?(:votes_count)
          updates[:votes_total] = value if has_attribute?(:votes_total)
          updates[:upvotes_count] = 1 if has_attribute?(:upvotes_count) && value.positive?
          updates[:downvotes_count] = 1 if has_attribute?(:downvotes_count) && value.negative?

          self.class.update_counters(id, **updates) if updates.any?
        end

        def decrement_vote_counters(value)
          return unless vote_fu_voteable_options[:counter_cache]

          updates = {}
          updates[:votes_count] = -1 if has_attribute?(:votes_count)
          updates[:votes_total] = -value if has_attribute?(:votes_total)
          updates[:upvotes_count] = -1 if has_attribute?(:upvotes_count) && value.positive?
          updates[:downvotes_count] = -1 if has_attribute?(:downvotes_count) && value.negative?

          self.class.update_counters(id, **updates) if updates.any?
        end

        def update_vote_counters(old_value, new_value)
          return unless vote_fu_voteable_options[:counter_cache]

          updates = {}

          if has_attribute?(:votes_total)
            updates[:votes_total] = new_value - old_value
          end

          if has_attribute?(:upvotes_count)
            old_up = old_value.positive? ? 1 : 0
            new_up = new_value.positive? ? 1 : 0
            updates[:upvotes_count] = new_up - old_up if new_up != old_up
          end

          if has_attribute?(:downvotes_count)
            old_down = old_value.negative? ? 1 : 0
            new_down = new_value.negative? ? 1 : 0
            updates[:downvotes_count] = new_down - old_down if new_down != old_down
          end

          self.class.update_counters(id, **updates) if updates.any?
        end

        # Broadcast vote updates via Turbo Streams and ActionCable
        def broadcast_vote_update(vote: nil, action: :updated)
          return unless vote_fu_voteable_options[:broadcasts]

          # Turbo Streams broadcast
          if respond_to?(:broadcast_replace_to)
            broadcast_replace_to(
              [self, :votes],
              target: "#{self.class.name.underscore}_#{id}_vote_widget",
              partial: "vote_fu/votes/widget",
              locals: { voteable: self }
            )
          end

          # ActionCable broadcast (for custom JS handling)
          if defined?(VoteFu::VotesChannel)
            VoteFu::VotesChannel.broadcast_vote_update(self, vote: vote, action: action)
          end
        end

        # Subscribe to vote updates via ActionCable
        def vote_stream_name(scope: nil)
          base = "vote_fu:#{self.class.name}:#{id}"
          scope.present? ? "#{base}:#{scope}" : base
        end
      end
    end
  end
end
