# frozen_string_literal: true

module VoteFu
  class ApplicationController < ::ApplicationController
    protect_from_forgery with: :exception

    private

    def find_voteable
      @voteable_type = params[:voteable_type]
      @voteable_id = params[:voteable_id]

      unless @voteable_type.present? && @voteable_id.present?
        raise VoteFu::Errors::VoteableNotFound, "voteable_type and voteable_id are required"
      end

      begin
        @voteable_class = @voteable_type.constantize
      rescue NameError
        raise VoteFu::Errors::VoteableNotFound, "Unknown voteable type: #{@voteable_type}"
      end

      @voteable = @voteable_class.find_by(id: @voteable_id)
      raise VoteFu::Errors::VoteableNotFound, "Voteable not found" unless @voteable
    end

    def current_voter
      # Override this in your ApplicationController to return the current user
      # Default implementation tries common patterns
      return @current_voter if defined?(@current_voter)

      @current_voter = if respond_to?(:current_user, true)
                         send(:current_user)
                       elsif defined?(Current) && Current.respond_to?(:user)
                         Current.user
                       end
    end

    def require_voter!
      return if current_voter.present?

      respond_to do |format|
        format.turbo_stream { head :unauthorized }
        format.html { redirect_to main_app.root_path, alert: "You must be signed in to vote" }
        format.json { render json: { error: "Unauthorized" }, status: :unauthorized }
      end
    end
  end
end
