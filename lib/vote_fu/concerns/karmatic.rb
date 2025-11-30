# frozen_string_literal: true

require "active_support/concern"

module VoteFu
  module Concerns
    module Karmatic
      extend ActiveSupport::Concern

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
        # @param association [Symbol] The association name
        # @param as [Symbol, nil] Custom foreign key name (without _id)
        # @param weight [Float, Array<Float>] Weight(s) for karma calculation
        def has_karma(association, as: nil, weight: 1.0)
          class_attribute :karma_sources, default: [] unless respond_to?(:karma_sources)

          foreign_key = as ? "#{as}_id" : "#{name.underscore}_id"
          weights = Array(weight)

          self.karma_sources = karma_sources + [{
            association: association,
            foreign_key: foreign_key,
            positive_weight: weights[0].to_f,
            negative_weight: weights[1]&.to_f || 0.0
          }]

          include VoteFu::Concerns::Karmatic::InstanceMethods
          extend VoteFu::Concerns::Karmatic::KarmaClassMethods
        end
      end

      module KarmaClassMethods
        # Order users by karma (requires subquery, can be slow)
        def by_karma(direction = :desc)
          # This is a simplified version - for production, consider caching karma
          all.sort_by(&:karma).tap { |r| r.reverse! if direction == :desc }
        end
      end

      module InstanceMethods
        # Calculate total karma from all sources
        #
        # @return [Integer] Total karma points
        def karma
          return 0 unless self.class.respond_to?(:karma_sources)

          self.class.karma_sources.sum do |source|
            calculate_karma_for(source)
          end.round
        end

        # Get karma breakdown by source
        #
        # @return [Array<Hash>] Array of {source:, value:} hashes
        def karma_breakdown
          return [] unless self.class.respond_to?(:karma_sources)

          self.class.karma_sources.map do |source|
            {
              source: source[:association],
              value: calculate_karma_for(source).round
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

        private

        def calculate_karma_for(source)
          klass = source[:association].to_s.classify.constantize

          # Get all voteables owned by this user
          voteable_ids = klass.where(source[:foreign_key] => id).pluck(:id)
          return 0.0 if voteable_ids.empty?

          # Count votes on those voteables
          votes = VoteFu::Vote.where(
            voteable_type: klass.name,
            voteable_id: voteable_ids
          )

          upvotes = votes.up.count
          downvotes = votes.down.count

          (upvotes * source[:positive_weight]) - (downvotes * source[:negative_weight])
        end
      end
    end
  end
end
