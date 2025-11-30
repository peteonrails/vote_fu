# frozen_string_literal: true

module VoteFu
  module Algorithms
    # Reddit's "Hot" ranking algorithm
    #
    # This algorithm balances popularity (vote score) with recency.
    # Items with high scores rise quickly, but decay over time,
    # allowing fresh content to surface.
    #
    # The formula uses logarithmic scaling for votes, so the first
    # 10 votes have the same impact as the next 100, then 1000, etc.
    # This prevents runaway popular items from dominating forever.
    #
    # @see https://medium.com/hacking-and-gonzo/how-reddit-ranking-algorithms-work-ef111e33d0d9
    #
    # @example
    #   Post.all.sort_by(&:hot_score).reverse
    #
    class RedditHot
      # Reddit's epoch (December 8, 2005)
      EPOCH = Time.utc(2005, 12, 8, 7, 46, 43).to_i

      # Calculate the hot score
      #
      # @param voteable [ActiveRecord::Base] The voteable object
      # @param gravity [Float] Not used in Reddit's algorithm but kept for API consistency
      # @return [Float] The hot score (higher = hotter)
      def self.call(voteable, gravity: 1.8)
        new(voteable).calculate
      end

      def initialize(voteable)
        @voteable = voteable
      end

      def calculate
        score = @voteable.plusminus
        order = Math.log10([score.abs, 1].max)
        sign = score <=> 0
        seconds = epoch_seconds

        # The score decays over time (45000 seconds ≈ 12.5 hours)
        (sign * order + seconds / 45_000.0).round(7)
      end

      private

      def epoch_seconds
        created_at = @voteable.try(:created_at) || Time.current
        created_at.to_i - EPOCH
      end
    end
  end
end
