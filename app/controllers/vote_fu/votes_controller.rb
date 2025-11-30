# frozen_string_literal: true

module VoteFu
  class VotesController < ApplicationController
    before_action :require_voter!
    before_action :find_voteable

    # POST /vote_fu/votes
    # Creates or updates a vote
    def create
      value = vote_value_from_params

      if VoteFu.configuration.allow_recast
        @vote = current_voter.vote_on(@voteable, value: value, scope: vote_scope)
      else
        existing = find_existing_vote
        if existing
          respond_with_error("You have already voted on this item")
          return
        end
        @vote = current_voter.vote_on(@voteable, value: value, scope: vote_scope)
      end

      respond_with_vote(:created)
    rescue StandardError => e
      respond_with_error(e.message)
    end

    # PATCH/PUT /vote_fu/votes/:id
    # Updates an existing vote's value
    def update
      @vote = Vote.find_by(id: params[:id], voter: current_voter)

      unless @vote
        respond_with_error("Vote not found")
        return
      end

      unless VoteFu.configuration.allow_recast
        respond_with_error("Vote recasting is disabled")
        return
      end

      value = vote_value_from_params
      @vote.update!(value: value)
      @voteable.reload

      respond_with_vote(:ok)
    rescue StandardError => e
      respond_with_error(e.message)
    end

    # DELETE /vote_fu/votes/:id
    # Removes a vote
    def destroy
      @vote = if params[:id].present? && params[:id] != "remove"
                Vote.find_by(id: params[:id], voter: current_voter)
              else
                find_existing_vote
              end

      unless @vote
        respond_with_error("Vote not found")
        return
      end

      @vote.destroy!
      @voteable.reload

      respond_to do |format|
        format.turbo_stream { render_vote_turbo_stream(:removed) }
        format.html { redirect_back fallback_location: main_app.root_path }
        format.json { render json: vote_json_response(:removed), status: :ok }
      end
    rescue StandardError => e
      respond_with_error(e.message)
    end

    # POST /vote_fu/votes/toggle
    # Toggles between upvote/remove or downvote/remove
    def toggle
      direction = params[:direction]&.to_sym || :up
      existing = find_existing_vote

      if existing
        if (direction == :up && existing.up?) || (direction == :down && existing.down?)
          # Same direction - remove the vote
          existing.destroy!
          @voteable.reload
          @vote = nil

          respond_to do |format|
            format.turbo_stream { render_vote_turbo_stream(:removed) }
            format.html { redirect_back fallback_location: main_app.root_path }
            format.json { render json: vote_json_response(:removed), status: :ok }
          end
        else
          # Different direction - change the vote (if allowed)
          if VoteFu.configuration.allow_recast
            value = direction == :up ? 1 : -1
            existing.update!(value: value)
            @vote = existing
            @voteable.reload
            respond_with_vote(:ok)
          else
            respond_with_error("Vote recasting is disabled")
          end
        end
      else
        # No existing vote - create one
        value = direction == :up ? 1 : -1
        @vote = current_voter.vote_on(@voteable, value: value, scope: vote_scope)
        respond_with_vote(:created)
      end
    rescue StandardError => e
      respond_with_error(e.message)
    end

    private

    def vote_scope
      params[:scope].presence
    end

    def vote_value_from_params
      if params[:value].present?
        params[:value].to_i
      elsif params[:direction].present?
        case params[:direction].to_sym
        when :up, :upvote then 1
        when :down, :downvote then -1
        else 1
        end
      else
        1
      end
    end

    def find_existing_vote
      Vote.find_by(
        voter: current_voter,
        voteable: @voteable,
        scope: vote_scope
      )
    end

    def respond_with_vote(status)
      @voteable.reload

      respond_to do |format|
        format.turbo_stream { render_vote_turbo_stream(status == :created ? :created : :updated) }
        format.html { redirect_back fallback_location: main_app.root_path }
        format.json { render json: vote_json_response(:success), status: status }
      end
    end

    def respond_with_error(message)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            vote_dom_id(:error),
            partial: "vote_fu/votes/error",
            locals: { message: message }
          ), status: :unprocessable_entity
        end
        format.html do
          redirect_back fallback_location: main_app.root_path, alert: message
        end
        format.json do
          render json: { error: message }, status: :unprocessable_entity
        end
      end
    end

    def render_vote_turbo_stream(action)
      render turbo_stream: [
        turbo_stream.replace(
          vote_dom_id(:widget),
          partial: "vote_fu/votes/widget",
          locals: vote_locals.merge(action: action)
        ),
        turbo_stream.replace(
          vote_dom_id(:count),
          partial: "vote_fu/votes/count",
          locals: vote_locals
        )
      ]
    end

    def vote_dom_id(suffix)
      scope_part = vote_scope.present? ? "_#{vote_scope}" : ""
      "vote_fu_#{@voteable.model_name.singular}_#{@voteable.id}#{scope_part}_#{suffix}"
    end

    def vote_locals
      {
        voteable: @voteable,
        voter: current_voter,
        vote: @vote,
        scope: vote_scope
      }
    end

    def vote_json_response(status)
      {
        status: status,
        voteable_type: @voteable.class.name,
        voteable_id: @voteable.id,
        scope: vote_scope,
        vote: @vote&.as_json(only: %i[id value created_at]),
        stats: {
          votes_for: @voteable.votes_for(scope: vote_scope),
          votes_against: @voteable.votes_against(scope: vote_scope),
          votes_total: @voteable.votes_total(scope: vote_scope),
          votes_count: @voteable.votes_count(scope: vote_scope),
          plusminus: @voteable.plusminus(scope: vote_scope),
          percent_for: @voteable.percent_for(scope: vote_scope)
        },
        current_vote_direction: @vote&.direction
      }
    end
  end
end
