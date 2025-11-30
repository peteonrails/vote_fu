# frozen_string_literal: true

module VoteFu
  class LikeButtonComponent < ViewComponent::Base
    # Simple like button (upvote only, social media style)
    #
    # @param voteable [ActiveRecord::Base] The voteable record
    # @param voter [ActiveRecord::Base, nil] The current voter
    # @param scope [String, Symbol, nil] Vote scope
    # @param liked_label [String] Label when liked
    # @param unliked_label [String] Label when not liked
    # @param show_count [Boolean] Show like count
    # @param variant [Symbol] Button style (:default, :compact, :pill)
    def initialize(
      voteable:,
      voter: nil,
      scope: nil,
      liked_label: "♥",
      unliked_label: "♡",
      show_count: true,
      variant: :default
    )
      @voteable = voteable
      @voter = voter
      @scope = scope
      @liked_label = liked_label
      @unliked_label = unliked_label
      @show_count = show_count
      @variant = variant
    end

    def call
      tag.div(**wrapper_attributes) do
        safe_join([
          like_button,
          (count_display if @show_count)
        ].compact)
      end
    end

    private

    def wrapper_attributes
      {
        id: dom_id(:widget),
        class: wrapper_classes,
        data: stimulus_data
      }
    end

    def wrapper_classes
      classes = ["vote-fu-like-widget"]
      classes << "vote-fu-like-widget--#{@variant}" unless @variant == :default
      classes << "vote-fu-liked" if liked?
      classes.join(" ")
    end

    def stimulus_data
      {
        controller: "vote-fu",
        vote_fu_voteable_type_value: @voteable.class.name,
        vote_fu_voteable_id_value: @voteable.id,
        vote_fu_scope_value: @scope,
        vote_fu_voted_value: liked?,
        vote_fu_direction_value: liked? ? "up" : nil
      }
    end

    def like_button
      if @voter
        form_with(url: toggle_path, method: :post, data: turbo_form_data) do |f|
          safe_join([
            f.hidden_field(:voteable_type, value: @voteable.class.name),
            f.hidden_field(:voteable_id, value: @voteable.id),
            f.hidden_field(:scope, value: @scope),
            f.hidden_field(:direction, value: :up),
            tag.button(
              liked? ? @liked_label : @unliked_label,
              type: :submit,
              class: button_classes,
              title: liked? ? "Unlike" : "Like",
              data: { vote_fu_target: "likeBtn" }
            )
          ])
        end
      else
        tag.span(@unliked_label, class: "vote-fu-btn vote-fu-like vote-fu-disabled")
      end
    end

    def count_display
      tag.span(
        like_count,
        id: dom_id(:count),
        class: "vote-fu-count",
        data: { vote_fu_target: "count" }
      )
    end

    def button_classes
      classes = ["vote-fu-btn", "vote-fu-like"]
      classes << "vote-fu-active" if liked?
      classes.join(" ")
    end

    def turbo_form_data
      { turbo_stream: true, action: "submit->vote-fu#vote" }
    end

    def current_vote
      return @current_vote if defined?(@current_vote)

      @current_vote = @voter && @voteable.received_votes.find_by(
        voter: @voter,
        scope: @scope
      )
    end

    def liked?
      current_vote&.up?
    end

    def like_count
      @voteable.votes_for(scope: @scope)
    end

    def toggle_path
      VoteFu::Engine.routes.url_helpers.toggle_votes_path
    end

    def dom_id(suffix)
      scope_part = @scope.present? ? "_#{@scope}" : ""
      "vote_fu_#{@voteable.model_name.singular}_#{@voteable.id}#{scope_part}_#{suffix}"
    end
  end
end
