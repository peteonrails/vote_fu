# frozen_string_literal: true

module VoteFu
  class VotesChannel < ApplicationCable::Channel
    # Subscribe to vote updates for a specific voteable
    #
    # Params:
    #   voteable_type: "Post"
    #   voteable_id: 123
    #   scope: "quality" (optional)
    #
    def subscribed
      voteable = find_voteable
      return reject unless voteable

      stream_for voteable_stream_name
    end

    def unsubscribed
      stop_all_streams
    end

    # Broadcast vote update to all subscribers
    #
    # Called from Vote model callbacks or controller
    #
    def self.broadcast_vote_update(voteable, vote: nil, action: :updated)
      return unless VoteFu.configuration.turbo_broadcasts

      scopes = [nil] + voteable.received_votes.distinct.pluck(:scope).compact

      scopes.each do |scope|
        stream_name = stream_name_for(voteable, scope)

        ActionCable.server.broadcast(stream_name, {
          type: "vote_update",
          action: action,
          voteable_type: voteable.class.name,
          voteable_id: voteable.id,
          scope: scope,
          vote: vote&.as_json(only: %i[id value created_at]),
          stats: vote_stats(voteable, scope),
          html: render_widget_html(voteable, scope)
        })
      end
    end

    # Broadcast to all subscribers of a voteable (any scope)
    def self.broadcast_to_voteable(voteable, message)
      stream_name = "vote_fu:#{voteable.class.name}:#{voteable.id}"
      ActionCable.server.broadcast(stream_name, message)
    end

    private

    def find_voteable
      type = params[:voteable_type]
      id = params[:voteable_id]

      return nil unless type.present? && id.present?

      begin
        type.constantize.find_by(id: id)
      rescue NameError
        nil
      end
    end

    def voteable_stream_name
      self.class.stream_name_for(
        find_voteable,
        params[:scope]
      )
    end

    def self.stream_name_for(voteable, scope = nil)
      base = "vote_fu:#{voteable.class.name}:#{voteable.id}"
      scope.present? ? "#{base}:#{scope}" : base
    end

    def self.vote_stats(voteable, scope)
      {
        votes_for: voteable.votes_for(scope: scope),
        votes_against: voteable.votes_against(scope: scope),
        votes_total: voteable.votes_total(scope: scope),
        votes_count: voteable.votes_count(scope: scope),
        plusminus: voteable.plusminus(scope: scope),
        percent_for: voteable.percent_for(scope: scope),
        wilson_score: voteable.wilson_score(scope: scope)
      }
    end

    def self.render_widget_html(voteable, scope)
      # Return nil - let the client handle rendering
      # This avoids needing a renderer context
      nil
    end
  end
end
