# frozen_string_literal: true

module VoteFu
  module Algorithms
    # Wilson Score Confidence Interval for Bernoulli Parameter
    #
    # This algorithm provides the lower bound of a Wilson score confidence interval.
    # It's excellent for ranking items by quality when you have binary ratings
    # (up/down votes). Unlike simple averages, it accounts for statistical uncertainty
    # when there are few votes.
    #
    # @see https://www.evanmiller.org/how-not-to-sort-by-average-rating.html
    #
    # @example
    #   post.wilson_score # => 0.85 (high confidence it's good)
    #
    class WilsonScore
      # Z-scores for common confidence levels
      Z_SCORES = {
        0.80 => 1.28,
        0.85 => 1.44,
        0.90 => 1.64,
        0.95 => 1.96,
        0.99 => 2.58
      }.freeze

      # Calculate the Wilson Score Lower Bound
      #
      # @param voteable [ActiveRecord::Base] The voteable object
      # @param confidence [Float] Confidence level (0.80 to 0.99)
      # @param scope [Symbol, nil] Optional voting scope
      # @return [Float] Score from 0.0 to 1.0
      def self.call(voteable, confidence: 0.95, scope: nil)
        new(voteable, confidence: confidence, scope: scope).calculate
      end

      def initialize(voteable, confidence:, scope:)
        @voteable = voteable
        @z = Z_SCORES.fetch(confidence) { Z_SCORES[0.95] }
        @scope = scope
      end

      def calculate
        n = total_votes
        return 0.0 if n.zero?

        pos = positive_votes
        phat = pos / n

        # Wilson Score Interval lower bound formula
        numerator = phat + (@z**2 / (2 * n)) -
                    @z * Math.sqrt((phat * (1 - phat) + @z**2 / (4 * n)) / n)
        denominator = 1 + @z**2 / n

        (numerator / denominator).clamp(0.0, 1.0).round(6)
      end

      private

      def total_votes
        @voteable.votes_count(scope: @scope).to_f
      end

      def positive_votes
        @voteable.votes_for(scope: @scope).to_f
      end
    end
  end
end
