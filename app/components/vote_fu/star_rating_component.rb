# frozen_string_literal: true

module VoteFu
  class StarRatingComponent < ViewComponent::Base
    # Star rating component for 1-5 star ratings
    #
    # Uses vote values 1-5 to represent star ratings.
    #
    # @param voteable [ActiveRecord::Base] The voteable record
    # @param voter [ActiveRecord::Base, nil] The current voter
    # @param scope [String, Symbol, nil] Vote scope
    # @param max_stars [Integer] Maximum number of stars (default: 5)
    # @param filled_star [String] Character for filled star
    # @param empty_star [String] Character for empty star
    # @param half_star [String] Character for half star (used in average display)
    # @param show_average [Boolean] Show average rating
    # @param show_count [Boolean] Show vote count
    # @param readonly [Boolean] Disable voting (show average only)
    def initialize(
      voteable:,
      voter: nil,
      scope: nil,
      max_stars: 5,
      filled_star: "★",
      empty_star: "☆",
      half_star: "⯨",
      show_average: true,
      show_count: true,
      readonly: false
    )
      @voteable = voteable
      @voter = voter
      @scope = scope
      @max_stars = max_stars
      @filled_star = filled_star
      @empty_star = empty_star
      @half_star = half_star
      @show_average = show_average
      @show_count = show_count
      @readonly = readonly
    end

    def call
      tag.div(**wrapper_attributes) do
        safe_join([
          star_container,
          (rating_info if @show_average || @show_count)
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
      classes = ["vote-fu-star-rating"]
      classes << "vote-fu-star-rating--readonly" if @readonly || @voter.nil?
      classes << "vote-fu-star-rating--voted" if current_vote.present?
      classes.join(" ")
    end

    def stimulus_data
      {
        controller: "vote-fu-stars",
        vote_fu_stars_voteable_type_value: @voteable.class.name,
        vote_fu_stars_voteable_id_value: @voteable.id,
        vote_fu_stars_scope_value: @scope,
        vote_fu_stars_current_rating_value: current_rating,
        vote_fu_stars_max_stars_value: @max_stars
      }
    end

    def star_container
      tag.div(class: "vote-fu-stars") do
        if interactive?
          interactive_stars
        else
          readonly_stars
        end
      end
    end

    def interactive_stars
      safe_join(
        (1..@max_stars).map { |value| interactive_star(value) }
      )
    end

    def interactive_star(value)
      form_with(url: vote_path, method: :post, data: turbo_form_data) do |f|
        safe_join([
          f.hidden_field(:voteable_type, value: @voteable.class.name),
          f.hidden_field(:voteable_id, value: @voteable.id),
          f.hidden_field(:scope, value: @scope),
          f.hidden_field(:value, value: value),
          tag.button(
            value <= current_rating ? @filled_star : @empty_star,
            type: :submit,
            class: star_button_classes(value),
            title: "Rate #{value} star#{value == 1 ? "" : "s"}",
            data: {
              vote_fu_stars_target: "star",
              star_value: value
            }
          )
        ])
      end
    end

    def readonly_stars
      safe_join(
        (1..@max_stars).map { |value| readonly_star(value) }
      )
    end

    def readonly_star(value)
      avg = average_rating
      star_char = if value <= avg.floor
                    @filled_star
                  elsif value - 0.5 <= avg
                    @half_star
                  else
                    @empty_star
                  end

      tag.span(star_char, class: star_classes(value, avg))
    end

    def star_button_classes(value)
      classes = ["vote-fu-star-btn"]
      classes << "vote-fu-star-filled" if value <= current_rating
      classes.join(" ")
    end

    def star_classes(value, avg)
      classes = ["vote-fu-star"]
      classes << "vote-fu-star-filled" if value <= avg.floor
      classes << "vote-fu-star-half" if value > avg.floor && value - 0.5 <= avg
      classes.join(" ")
    end

    def rating_info
      tag.div(class: "vote-fu-star-info") do
        parts = []
        parts << tag.span("#{average_rating.round(1)}", class: "vote-fu-star-average") if @show_average
        parts << tag.span("(#{vote_count})", class: "vote-fu-star-count") if @show_count
        safe_join(parts, " ")
      end
    end

    def turbo_form_data
      { turbo_stream: true, action: "submit->vote-fu-stars#rate" }
    end

    def interactive?
      !@readonly && @voter.present?
    end

    def current_vote
      return @current_vote if defined?(@current_vote)

      @current_vote = @voter && @voteable.received_votes.find_by(
        voter: @voter,
        scope: @scope
      )
    end

    def current_rating
      current_vote&.value.to_i
    end

    def average_rating
      return @average_rating if defined?(@average_rating)

      votes = @voteable.received_votes.with_scope(@scope)
      @average_rating = votes.any? ? votes.average(:value).to_f : 0.0
    end

    def vote_count
      @voteable.received_votes.with_scope(@scope).count
    end

    def vote_path
      VoteFu::Engine.routes.url_helpers.votes_path
    end

    def dom_id(suffix)
      scope_part = @scope.present? ? "_#{@scope}" : ""
      "vote_fu_#{@voteable.model_name.singular}_#{@voteable.id}#{scope_part}_#{suffix}"
    end
  end
end
