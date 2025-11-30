# frozen_string_literal: true

module VoteFu
  module ApplicationCable
    class Connection < ActionCable::Connection::Base
      identified_by :current_voter

      def connect
        self.current_voter = find_verified_voter
      end

      private

      def find_verified_voter
        # Try common authentication patterns
        # Applications should override this in their own connection class
        if (voter = env["warden"]&.user)
          voter
        elsif (voter_id = cookies.encrypted[:voter_id])
          find_voter_by_id(voter_id)
        elsif (voter_id = request.session[:user_id] || request.session[:voter_id])
          find_voter_by_id(voter_id)
        else
          # Allow anonymous connections for public vote viewing
          nil
        end
      end

      def find_voter_by_id(id)
        # Try common user model names
        if defined?(User)
          User.find_by(id: id)
        elsif defined?(Account)
          Account.find_by(id: id)
        end
      end
    end
  end
end
