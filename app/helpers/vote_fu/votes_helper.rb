# frozen_string_literal: true

module VoteFu
  module VotesHelper
    # Renders the full vote widget with upvote/downvote buttons and count
    #
    # @param voteable [ActiveRecord::Base] The voteable record
    # @param options [Hash] Options hash
    # @option options [Object] :voter The current voter (defaults to current_user if available)
    # @option options [String, Symbol] :scope Vote scope for scoped voting
    # @option options [Boolean] :show_count Whether to show vote count (default: true)
    # @option options [String] :upvote_label Custom upvote button label (default: "▲")
    # @option options [String] :downvote_label Custom downvote button label (default: "▼")
    #
    # @example Basic usage
    #   <%= vote_widget @post %>
    #
    # @example With scope
    #   <%= vote_widget @post, scope: :quality %>
    #
    # @example Custom labels
    #   <%= vote_widget @post, upvote_label: "👍", downvote_label: "👎" %>
    #
    def vote_widget(voteable, options = {})
      voter = options.fetch(:voter) { default_voter }

      render partial: "vote_fu/votes/widget", locals: {
        voteable: voteable,
        voter: voter,
        scope: options[:scope],
        show_count: options.fetch(:show_count, true),
        upvote_label: options.fetch(:upvote_label, "▲"),
        downvote_label: options.fetch(:downvote_label, "▼")
      }
    end

    # Renders the vote count for a voteable
    #
    # @param voteable [ActiveRecord::Base] The voteable record
    # @param options [Hash] Options hash
    # @option options [String, Symbol] :scope Vote scope
    # @option options [Symbol] :format Display format (:plusminus, :total, :percentage, :split)
    #
    # @example Basic usage
    #   <%= vote_count @post %>
    #
    # @example With format
    #   <%= vote_count @post, format: :percentage %>
    #
    def vote_count(voteable, options = {})
      render partial: "vote_fu/votes/count", locals: {
        voteable: voteable,
        scope: options[:scope],
        format: options.fetch(:format, :plusminus)
      }
    end

    # Renders a like button (upvote-only, social media style)
    #
    # @param voteable [ActiveRecord::Base] The voteable record
    # @param options [Hash] Options hash
    # @option options [Object] :voter The current voter
    # @option options [String, Symbol] :scope Vote scope
    # @option options [String] :liked_label Label when liked (default: "♥")
    # @option options [String] :unliked_label Label when not liked (default: "♡")
    # @option options [Boolean] :show_count Show like count (default: true)
    # @option options [String] :class Additional CSS classes
    #
    # @example Basic usage
    #   <%= like_button @photo %>
    #
    # @example With custom labels
    #   <%= like_button @photo, liked_label: "❤️", unliked_label: "🤍" %>
    #
    def like_button(voteable, options = {})
      voter = options.fetch(:voter) { default_voter }

      render partial: "vote_fu/votes/like_button", locals: {
        voteable: voteable,
        voter: voter,
        scope: options[:scope],
        liked_label: options.fetch(:liked_label, "♥"),
        unliked_label: options.fetch(:unliked_label, "♡"),
        show_count: options.fetch(:show_count, true),
        class: options[:class]
      }
    end

    # Renders a standalone upvote button
    #
    # @param voteable [ActiveRecord::Base] The voteable record
    # @param options [Hash] Options hash
    #
    def upvote_button(voteable, options = {})
      voter = options.fetch(:voter) { default_voter }

      render partial: "vote_fu/votes/upvote_button", locals: {
        voteable: voteable,
        voter: voter,
        scope: options[:scope],
        label: options.fetch(:label, "▲"),
        class: options[:class]
      }
    end

    # Renders a standalone downvote button
    #
    # @param voteable [ActiveRecord::Base] The voteable record
    # @param options [Hash] Options hash
    #
    def downvote_button(voteable, options = {})
      voter = options.fetch(:voter) { default_voter }

      render partial: "vote_fu/votes/downvote_button", locals: {
        voteable: voteable,
        voter: voter,
        scope: options[:scope],
        label: options.fetch(:label, "▼"),
        class: options[:class]
      }
    end

    # Returns the DOM ID for a voteable's widget
    #
    # @param voteable [ActiveRecord::Base] The voteable record
    # @param suffix [Symbol, String] ID suffix (:widget, :count, :error)
    # @param scope [String, Symbol, nil] Vote scope
    # @return [String] The DOM ID
    #
    def vote_dom_id(voteable, suffix = :widget, scope: nil)
      scope_part = scope.present? ? "_#{scope}" : ""
      "vote_fu_#{voteable.model_name.singular}_#{voteable.id}#{scope_part}_#{suffix}"
    end

    # Checks if the current voter has voted on the voteable
    #
    # @param voteable [ActiveRecord::Base] The voteable record
    # @param options [Hash] Options hash
    # @option options [Object] :voter The voter to check
    # @option options [Symbol] :direction :up or :down to check specific direction
    # @option options [String, Symbol] :scope Vote scope
    # @return [Boolean]
    #
    def voted_on?(voteable, options = {})
      voter = options.fetch(:voter) { default_voter }
      return false unless voter

      voteable.voted_by?(voter, direction: options[:direction], scope: options[:scope])
    end

    # Returns the current vote direction for a voter on a voteable
    #
    # @param voteable [ActiveRecord::Base] The voteable record
    # @param options [Hash] Options hash
    # @return [Symbol, nil] :up, :down, or nil if not voted
    #
    def current_vote_direction(voteable, options = {})
      voter = options.fetch(:voter) { default_voter }
      return nil unless voter

      scope = options[:scope]
      vote = voteable.received_votes.find_by(voter: voter, scope: scope)
      vote&.direction
    end

    private

    def default_voter
      if respond_to?(:current_user, true)
        send(:current_user)
      elsif defined?(Current) && Current.respond_to?(:user)
        Current.user
      end
    end
  end
end
