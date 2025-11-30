# frozen_string_literal: true

require "active_support/concern"

module VoteFu
  module Concerns
    module Karmatic
      extend ActiveSupport::Concern

      # Default karma level thresholds
      DEFAULT_LEVELS = {
        0 => "Newcomer",
        10 => "Contributor",
        50 => "Active",
        100 => "Trusted",
        250 => "Veteran",
        500 => "Expert",
        1000 => "Legend"
      }.freeze

      class_methods do
        # Configure karma calculation based on votes on owned content
        #
        # @example Simple karma from posts
        #   class User < ApplicationRecord
        #     has_many :posts
        #     has_karma :posts
        #   end
        #
        # @example With custom foreign key
        #   class User < ApplicationRecord
        #     has_many :articles, foreign_key: :author_id
        #     has_karma :articles, as: :author
        #   end
        #
        # @example With weighted karma (upvotes worth 1, downvotes worth -0.5)
        #   class User < ApplicationRecord
        #     has_karma :posts, weight: [1.0, 0.5]
        #   end
        #
        # @example With time decay (votes older than 90 days worth less)
        #   class User < ApplicationRecord
        #     has_karma :posts, decay: { half_life: 90.days }
        #   end
        #
        # @example With scoped karma
        #   class User < ApplicationRecord
        #     has_karma :posts, scope: :quality
        #   end
        #
        # @param association [Symbol] The association name
        # @param as [Symbol, nil] Custom foreign key name (without _id)
        # @param weight [Float, Array<Float>] Weight(s) for karma calculation
        # @param decay [Hash, nil] Time decay options (:half_life, :floor)
        # @param scope [Symbol, nil] Only count votes with this scope
        def has_karma(association, as: nil, weight: 1.0, decay: nil, scope: nil)
          class_attribute :karma_sources, default: [] unless respond_to?(:karma_sources)
          class_attribute :karma_levels, default: DEFAULT_LEVELS.dup unless respond_to?(:karma_levels)

          foreign_key = as ? "#{as}_id" : "#{name.underscore}_id"
          weights = Array(weight)

          self.karma_sources = karma_sources + [{
            association: association,
            foreign_key: foreign_key,
            positive_weight: weights[0].to_f,
            negative_weight: weights[1]&.to_f || weights[0].to_f,
            decay: decay,
            scope: scope
          }]

          include VoteFu::Concerns::Karmatic::InstanceMethods
          extend VoteFu::Concerns::Karmatic::KarmaClassMethods
        end

        # Configure karma levels with custom thresholds
        #
        # @example Custom levels
        #   class User < ApplicationRecord
        #     set_karma_levels 0 => "Noob", 100 => "Pro", 1000 => "Elite"
        #   end
        def set_karma_levels(levels)
          self.karma_levels = levels
        end
      end

      module KarmaClassMethods
        # Order users by karma (requires subquery, can be slow)
        # For performance, consider adding a karma_cache column
        def by_karma(direction = :desc)
          if column_names.include?("karma_cache")
            order(karma_cache: direction)
          else
            all.sort_by(&:karma).tap { |r| r.reverse! if direction == :desc }
          end
        end

        # Users above a karma threshold
        def with_karma_above(threshold)
          if column_names.include?("karma_cache")
            where("karma_cache > ?", threshold)
          else
            select { |u| u.karma > threshold }
          end
        end

        # Users at or above a certain level
        def with_karma_level(level_name)
          threshold = karma_levels.key(level_name) || 0
          with_karma_above(threshold - 1)
        end
      end

      module InstanceMethods
        # Calculate total karma from all sources
        #
        # @param force [Boolean] Bypass cache
        # @return [Integer] Total karma points
        def karma(force: false)
          return 0 unless self.class.respond_to?(:karma_sources)

          # Use cached value if available and not forcing recalculation
          if !force && has_attribute?(:karma_cache) && karma_cache.present?
            return karma_cache
          end

          calculated = self.class.karma_sources.sum do |source|
            calculate_karma_for(source)
          end.round

          # Update cache if column exists
          update_karma_cache(calculated) if has_attribute?(:karma_cache) && force

          calculated
        end

        # Get karma for last N days only
        #
        # @param days [Integer] Number of days to look back
        # @return [Integer]
        def recent_karma(days: 30)
          return 0 unless self.class.respond_to?(:karma_sources)

          self.class.karma_sources.sum do |source|
            calculate_karma_for(source, since: days.days.ago)
          end.round
        end

        # Get karma breakdown by source
        #
        # @return [Array<Hash>] Array of {source:, value:, recent:} hashes
        def karma_breakdown
          return [] unless self.class.respond_to?(:karma_sources)

          self.class.karma_sources.map do |source|
            {
              source: source[:association],
              value: calculate_karma_for(source).round,
              recent: calculate_karma_for(source, since: 30.days.ago).round
            }
          end
        end

        # Get karma for a specific source
        #
        # @param association [Symbol] The association name
        # @return [Integer]
        def karma_for(association)
          source = self.class.karma_sources.find { |s| s[:association] == association }
          return 0 unless source

          calculate_karma_for(source).round
        end

        # Get the user's karma level
        #
        # @return [String] Level name
        def karma_level
          return "Unknown" unless self.class.respond_to?(:karma_levels)

          current_karma = karma
          level = "Unknown"

          self.class.karma_levels.sort_by { |k, _| k }.each do |threshold, name|
            level = name if current_karma >= threshold
          end

          level
        end

        # Get progress to next karma level
        #
        # @return [Hash] { current_level:, next_level:, progress:, karma_needed: }
        def karma_progress
          return nil unless self.class.respond_to?(:karma_levels)

          current_karma = karma
          sorted_levels = self.class.karma_levels.sort_by { |k, _| k }

          current_threshold = 0
          current_level = sorted_levels.first&.last || "Unknown"
          next_threshold = nil
          next_level = nil

          sorted_levels.each_with_index do |(threshold, name), i|
            if current_karma >= threshold
              current_threshold = threshold
              current_level = name
              # Only set next level if there IS a next level
              if i < sorted_levels.length - 1
                next_data = sorted_levels[i + 1]
                next_threshold = next_data[0]
                next_level = next_data[1]
              else
                next_threshold = nil
                next_level = nil
              end
            end
          end

          if next_threshold.nil?
            # Already at max level
            {
              current_level: current_level,
              next_level: nil,
              progress: 100.0,
              karma_needed: 0
            }
          else
            range = next_threshold - current_threshold
            progress_in_range = current_karma - current_threshold
            {
              current_level: current_level,
              next_level: next_level,
              progress: ((progress_in_range.to_f / range) * 100).round(1),
              karma_needed: next_threshold - current_karma
            }
          end
        end

        # Check if user has at least a certain karma level
        #
        # @param level_name [String] The level name to check
        # @return [Boolean]
        def karma_level?(level_name)
          return false unless self.class.respond_to?(:karma_levels)

          threshold = self.class.karma_levels.key(level_name)
          return false unless threshold

          karma >= threshold
        end

        # Update the karma cache (call periodically or after votes)
        def update_karma_cache(value = nil)
          return unless has_attribute?(:karma_cache)

          value ||= self.class.karma_sources.sum { |s| calculate_karma_for(s) }.round
          update_column(:karma_cache, value)
        end

        # Alias for update_karma_cache
        def recalculate_karma!
          update_karma_cache
          karma(force: true)
        end

        private

        def calculate_karma_for(source, since: nil)
          klass = source[:association].to_s.classify.constantize

          # Get all voteables owned by this user
          voteable_ids = klass.where(source[:foreign_key] => id).pluck(:id)
          return 0.0 if voteable_ids.empty?

          # Build votes query
          votes = VoteFu::Vote.where(
            voteable_type: klass.name,
            voteable_id: voteable_ids
          )

          # Apply scope filter if specified
          votes = votes.with_scope(source[:scope]) if source[:scope]

          # Apply time filter if specified
          votes = votes.where(created_at: since..) if since

          # If decay is enabled, calculate weighted sum
          if source[:decay]
            calculate_decayed_karma(votes, source)
          else
            upvotes = votes.up.count
            downvotes = votes.down.count
            (upvotes * source[:positive_weight]) - (downvotes * source[:negative_weight])
          end
        end

        def calculate_decayed_karma(votes, source)
          half_life = source[:decay][:half_life] || 90.days
          floor = source[:decay][:floor] || 0.1

          now = Time.current
          total = 0.0

          # This is slow for many votes - consider caching
          votes.find_each do |vote|
            age = now - vote.created_at
            decay_factor = [2**(-age / half_life), floor].max

            weight = vote.up? ? source[:positive_weight] : -source[:negative_weight]
            total += weight * decay_factor
          end

          total
        end
      end
    end
  end
end
