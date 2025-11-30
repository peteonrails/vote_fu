# frozen_string_literal: true

module VoteFu
  module Algorithms
    # Hacker News ranking algorithm
    #
    # This algorithm heavily penalizes older content. Items decay
    # rapidly based on age, making it suitable for fast-moving
    # content feeds where freshness is paramount.
    #
    # Formula: Score = (P - 1) / (T + 2)^G
    # Where:
    #   P = points (plusminus score)
    #   T = age in hours
    #   G = gravity (default 1.8)
    #
    # @see https://medium.com/hacking-and-gonzo/how-hacker-news-ranking-algorithm-works-1d9b0cf2c08d
    #
    # @example
    #   Post.all.sort_by { |p| p.hacker_news_score }.reverse
    #
    class HackerNews
      # Calculate the Hacker News score
      #
      # @param voteable [ActiveRecord::Base] The voteable object
      # @param gravity [Float] Decay rate (higher = faster decay, default 1.8)
      # @return [Float] The score (higher = better)
      def self.call(voteable, gravity: 1.8)
        new(voteable, gravity: gravity).calculate
      end

      def initialize(voteable, gravity:)
        @voteable = voteable
        @gravity = gravity
      end

      def calculate
        points = [@voteable.plusminus - 1, 0].max
        age_hours = hours_since_creation

        return 0.0 if age_hours.negative?

        points / ((age_hours + 2)**@gravity)
      end

      private

      def hours_since_creation
        created_at = @voteable.try(:created_at) || Time.current
        (Time.current - created_at) / 1.hour
      end
    end
  end
end
