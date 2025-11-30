# frozen_string_literal: true

require "active_support/concern"

module VoteFu
  module Concerns
    module Voter
      extend ActiveSupport::Concern

      class_methods do
        # Configure a model to cast votes
        #
        # @example Basic usage
        #   class User < ApplicationRecord
        #     acts_as_voter
        #   end
        #
        # @example With options
        #   class User < ApplicationRecord
        #     acts_as_voter allow_self_vote: false
        #   end
        #
        # @param options [Hash] Configuration options
        # @option options [Boolean] :allow_self_vote (false) Allow voting on self
        def acts_as_voter(**options)
          class_attribute :vote_fu_voter_options, default: {
            allow_self_vote: VoteFu.configuration.allow_self_vote
          }.merge(options)

          has_many :cast_votes,
                   class_name: "VoteFu::Vote",
                   as: :voter,
                   dependent: :destroy,
                   inverse_of: :voter

          include VoteFu::Concerns::Voter::InstanceMethods
          extend VoteFu::Concerns::Voter::ClassMethods
        end

        # Declare what models this voter votes on (generates helper methods)
        #
        # @example
        #   class User < ApplicationRecord
        #     acts_as_voter
        #     votes_on :posts, :comments
        #   end
        #
        #   user.upvote_post(post)
        #   user.downvote_comment(comment)
        def votes_on(*model_names, **options)
          acts_as_voter unless respond_to?(:vote_fu_voter_options)

          model_names.each do |model_name|
            define_voting_methods_for(model_name, **options)
          end
        end

        private

        def define_voting_methods_for(model_name, scopes: nil, **)
          singular = model_name.to_s.singularize

          # user.upvote_post(post)
          define_method(:"upvote_#{singular}") do |voteable, scope: nil|
            vote_on(voteable, value: 1, scope: scope)
          end

          # user.downvote_post(post)
          define_method(:"downvote_#{singular}") do |voteable, scope: nil|
            vote_on(voteable, value: -1, scope: scope)
          end

          # user.unvote_post(post)
          define_method(:"unvote_#{singular}") do |voteable, scope: nil|
            unvote(voteable, scope: scope)
          end

          # user.toggle_vote_post(post)
          define_method(:"toggle_vote_#{singular}") do |voteable, scope: nil|
            toggle_vote(voteable, scope: scope)
          end

          # user.vote_on_post(post, value: 5)
          define_method(:"vote_on_#{singular}") do |voteable, value:, scope: nil|
            vote_on(voteable, value: value, scope: scope)
          end

          # user.voted_on_post?(post)
          define_method(:"voted_on_#{singular}?") do |voteable, direction: nil, scope: nil|
            voted_on?(voteable, direction: direction, scope: scope)
          end

          # user.vote_value_for_post(post)
          define_method(:"vote_value_for_#{singular}") do |voteable, scope: nil|
            vote_value_for(voteable, scope: scope)
          end

          # Generate scoped methods if scopes provided
          scopes&.each do |scope_name|
            define_method(:"vote_on_#{singular}_#{scope_name}") do |voteable, value:|
              vote_on(voteable, value: value, scope: scope_name)
            end

            define_method(:"upvote_#{singular}_#{scope_name}") do |voteable|
              vote_on(voteable, value: 1, scope: scope_name)
            end

            define_method(:"downvote_#{singular}_#{scope_name}") do |voteable|
              vote_on(voteable, value: -1, scope: scope_name)
            end
          end
        end
      end

      module ClassMethods
        # Find voters who voted on a specific item
        def voted_on(voteable, direction: nil, scope: nil)
          votes = VoteFu::Vote.where(voteable: voteable).with_scope(scope)
          votes = votes.up if direction == :up
          votes = votes.down if direction == :down

          where(id: votes.where(voter_type: name).select(:voter_id))
        end
      end

      module InstanceMethods
        # Cast a vote on a voteable
        #
        # @param voteable [ActiveRecord::Base] The item to vote on
        # @param value [Integer] Vote value (positive for up, negative for down)
        # @param scope [Symbol, nil] Optional voting scope
        # @return [VoteFu::Vote] The created or updated vote
        # @raise [VoteFu::SelfVoteError] If self-voting is disabled
        # @raise [VoteFu::AlreadyVotedError] If already voted and recast disabled
        def vote_on(voteable, value:, scope: nil)
          validate_vote!(voteable, value)

          existing = find_vote_for(voteable, scope: scope)

          if existing
            handle_existing_vote(existing, value)
          else
            cast_votes.create!(voteable: voteable, value: value, scope: scope)
          end
        end

        # Upvote a voteable (+1)
        #
        # @param voteable [ActiveRecord::Base] The item to vote on
        # @param scope [Symbol, nil] Optional voting scope
        # @return [VoteFu::Vote]
        def upvote(voteable, scope: nil)
          vote_on(voteable, value: 1, scope: scope)
        end

        # Downvote a voteable (-1)
        #
        # @param voteable [ActiveRecord::Base] The item to vote on
        # @param scope [Symbol, nil] Optional voting scope
        # @return [VoteFu::Vote]
        def downvote(voteable, scope: nil)
          vote_on(voteable, value: -1, scope: scope)
        end

        # Remove a vote
        #
        # @param voteable [ActiveRecord::Base] The item to unvote
        # @param scope [Symbol, nil] Optional voting scope
        # @return [VoteFu::Vote, nil] The destroyed vote or nil
        def unvote(voteable, scope: nil)
          find_vote_for(voteable, scope: scope)&.destroy
        end

        # Toggle vote: remove if exists, upvote if not
        #
        # @param voteable [ActiveRecord::Base] The item to toggle
        # @param scope [Symbol, nil] Optional voting scope
        # @return [VoteFu::Vote, nil]
        def toggle_vote(voteable, scope: nil)
          existing = find_vote_for(voteable, scope: scope)
          if existing
            existing.destroy
            nil
          else
            upvote(voteable, scope: scope)
          end
        end

        # Check if voted on an item
        #
        # @param voteable [ActiveRecord::Base] The item to check
        # @param direction [Symbol, Integer, nil] :up, :down, or specific value
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Boolean]
        def voted_on?(voteable, direction: nil, scope: nil)
          vote = find_vote_for(voteable, scope: scope)
          return false unless vote

          case direction
          when nil then true
          when :up, :positive then vote.up?
          when :down, :negative then vote.down?
          when Integer then vote.value == direction
          else false
          end
        end

        # Get the vote value for an item
        #
        # @param voteable [ActiveRecord::Base] The item
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Integer, nil]
        def vote_value_for(voteable, scope: nil)
          find_vote_for(voteable, scope: scope)&.value
        end

        # Get the vote direction for an item
        #
        # @param voteable [ActiveRecord::Base] The item
        # @param scope [Symbol, nil] Optional voting scope
        # @return [Symbol, nil] :up, :down, :neutral, or nil
        def vote_direction_for(voteable, scope: nil)
          find_vote_for(voteable, scope: scope)&.direction
        end

        # Get all items of a class that this voter voted on
        #
        # @param klass [Class] The voteable class
        # @param scope [Symbol, nil] Optional voting scope
        # @return [ActiveRecord::Relation]
        def voted_items(klass, scope: nil)
          klass.joins(:received_votes)
               .where(vote_fu_votes: { voter: self, scope: scope })
               .distinct
        end

        # Count of votes cast
        #
        # @param direction [Symbol, nil] :up, :down, or nil for all
        # @return [Integer]
        def vote_count(direction = nil)
          votes = cast_votes
          case direction
          when :up, :positive then votes.up.count
          when :down, :negative then votes.down.count
          else votes.count
          end
        end

        private

        def find_vote_for(voteable, scope: nil)
          cast_votes.find_by(voteable: voteable, scope: scope)
        end

        def validate_vote!(voteable, value)
          if voteable == self && !vote_fu_voter_options[:allow_self_vote]
            raise VoteFu::SelfVoteError
          end

          raise VoteFu::InvalidVoteValueError unless value.is_a?(Integer)
        end

        def handle_existing_vote(existing, value)
          if VoteFu.configuration.allow_recast
            existing.update!(value: value)
            existing
          else
            raise VoteFu::AlreadyVotedError
          end
        end
      end
    end
  end
end
