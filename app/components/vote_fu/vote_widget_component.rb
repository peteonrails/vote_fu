# frozen_string_literal: true

module VoteFu
  class VoteWidgetComponent < ViewComponent::Base
    # The voteable record
    attr_reader :voteable

    # @param voteable [ActiveRecord::Base] The voteable record
    # @param voter [ActiveRecord::Base, nil] The current voter
    # @param scope [String, Symbol, nil] Vote scope for scoped voting
    # @param variant [Symbol] Widget style (:default, :compact, :vertical, :large)
    # @param upvote_label [String] Upvote button label
    # @param downvote_label [String] Downvote button label
    # @param show_count [Boolean] Whether to show vote count
    # @param count_format [Symbol] Count format (:plusminus, :total, :split)
    def initialize(
      voteable:,
      voter: nil,
      scope: nil,
      variant: :default,
      upvote_label: "▲",
      downvote_label: "▼",
      show_count: true,
      count_format: :plusminus
    )
      @voteable = voteable
      @voter = voter
      @scope = scope
      @variant = variant
      @upvote_label = upvote_label
      @downvote_label = downvote_label
      @show_count = show_count
      @count_format = count_format
    end

    def call
      tag.div(**wrapper_attributes) do
        safe_join([
          upvote_button,
          (count_display if @show_count),
          downvote_button
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
      classes = ["vote-fu-widget"]
      classes << "vote-fu-widget--#{@variant}" unless @variant == :default
      classes << "vote-fu-voted-up" if voted_up?
      classes << "vote-fu-voted-down" if voted_down?
      classes.join(" ")
    end

    def stimulus_data
      {
        controller: "vote-fu",
        vote_fu_voteable_type_value: @voteable.class.name,
        vote_fu_voteable_id_value: @voteable.id,
        vote_fu_scope_value: @scope,
        vote_fu_voted_value: current_vote.present?,
        vote_fu_direction_value: current_vote&.direction
      }
    end

    def upvote_button
      if @voter
        form_with(url: toggle_path, method: :post, data: turbo_form_data) do |f|
          safe_join([
            f.hidden_field(:voteable_type, value: @voteable.class.name),
            f.hidden_field(:voteable_id, value: @voteable.id),
            f.hidden_field(:scope, value: @scope),
            f.hidden_field(:direction, value: :up),
            tag.button(
              @upvote_label,
              type: :submit,
              class: upvote_button_classes,
              title: voted_up? ? "Remove upvote" : "Upvote",
              data: { vote_fu_target: "upvoteBtn" }
            )
          ])
        end
      else
        tag.span(@upvote_label, class: "vote-fu-btn vote-fu-upvote vote-fu-disabled")
      end
    end

    def downvote_button
      if @voter
        form_with(url: toggle_path, method: :post, data: turbo_form_data) do |f|
          safe_join([
            f.hidden_field(:voteable_type, value: @voteable.class.name),
            f.hidden_field(:voteable_id, value: @voteable.id),
            f.hidden_field(:scope, value: @scope),
            f.hidden_field(:direction, value: :down),
            tag.button(
              @downvote_label,
              type: :submit,
              class: downvote_button_classes,
              title: voted_down? ? "Remove downvote" : "Downvote",
              data: { vote_fu_target: "downvoteBtn" }
            )
          ])
        end
      else
        tag.span(@downvote_label, class: "vote-fu-btn vote-fu-downvote vote-fu-disabled")
      end
    end

    def count_display
      tag.span(
        formatted_count,
        id: dom_id(:count),
        class: "vote-fu-count",
        data: { vote_fu_target: "count" }
      )
    end

    def formatted_count
      case @count_format
      when :total
        @voteable.votes_total(scope: @scope)
      when :split
        "+#{@voteable.votes_for(scope: @scope)} / -#{@voteable.votes_against(scope: @scope)}"
      else
        @voteable.plusminus(scope: @scope)
      end
    end

    def upvote_button_classes
      classes = ["vote-fu-btn", "vote-fu-upvote"]
      classes << "vote-fu-active" if voted_up?
      classes.join(" ")
    end

    def downvote_button_classes
      classes = ["vote-fu-btn", "vote-fu-downvote"]
      classes << "vote-fu-active" if voted_down?
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

    def voted_up?
      current_vote&.up?
    end

    def voted_down?
      current_vote&.down?
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
