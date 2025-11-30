# frozen_string_literal: true

module VoteFu
  class ReactionBarComponent < ViewComponent::Base
    # Reaction bar component for emoji reactions (like Slack, GitHub, etc.)
    #
    # Uses scoped voting where each reaction type is a scope.
    # Vote values indicate the reaction emoji index.
    #
    # @param voteable [ActiveRecord::Base] The voteable record
    # @param voter [ActiveRecord::Base, nil] The current voter
    # @param reactions [Array<Hash>] Array of reaction configs: { emoji:, label:, scope: }
    # @param show_counts [Boolean] Show reaction counts
    # @param show_users [Boolean] Show who reacted (requires extra query)
    # @param max_users [Integer] Max user names to show per reaction
    # @param allow_multiple [Boolean] Allow user to add multiple reactions
    def initialize(
      voteable:,
      voter: nil,
      reactions: default_reactions,
      show_counts: true,
      show_users: false,
      max_users: 3,
      allow_multiple: true
    )
      @voteable = voteable
      @voter = voter
      @reactions = reactions
      @show_counts = show_counts
      @show_users = show_users
      @max_users = max_users
      @allow_multiple = allow_multiple
    end

    def call
      tag.div(**wrapper_attributes) do
        safe_join([
          reactions_container,
          (add_reaction_button if @voter && @allow_multiple)
        ].compact)
      end
    end

    private

    def default_reactions
      [
        { emoji: "👍", label: "Like", scope: "like" },
        { emoji: "❤️", label: "Love", scope: "love" },
        { emoji: "😂", label: "Laugh", scope: "laugh" },
        { emoji: "😮", label: "Wow", scope: "wow" },
        { emoji: "😢", label: "Sad", scope: "sad" },
        { emoji: "😡", label: "Angry", scope: "angry" }
      ]
    end

    def wrapper_attributes
      {
        id: dom_id(:reactions),
        class: "vote-fu-reaction-bar",
        data: stimulus_data
      }
    end

    def stimulus_data
      {
        controller: "vote-fu-reactions",
        vote_fu_reactions_voteable_type_value: @voteable.class.name,
        vote_fu_reactions_voteable_id_value: @voteable.id,
        vote_fu_reactions_allow_multiple_value: @allow_multiple
      }
    end

    def reactions_container
      tag.div(class: "vote-fu-reactions") do
        safe_join(@reactions.map { |reaction| reaction_button(reaction) })
      end
    end

    def reaction_button(reaction)
      scope = reaction[:scope]
      count = reaction_count(scope)
      user_reacted = user_reacted?(scope)

      return nil if count.zero? && !@voter

      tag.div(
        class: reaction_wrapper_classes(user_reacted, count),
        data: { scope: scope }
      ) do
        if @voter
          interactive_reaction(reaction, count, user_reacted)
        else
          readonly_reaction(reaction, count)
        end
      end
    end

    def interactive_reaction(reaction, count, user_reacted)
      form_with(url: toggle_path, method: :post, data: turbo_form_data) do |f|
        safe_join([
          f.hidden_field(:voteable_type, value: @voteable.class.name),
          f.hidden_field(:voteable_id, value: @voteable.id),
          f.hidden_field(:scope, value: reaction[:scope]),
          f.hidden_field(:direction, value: :up),
          tag.button(
            reaction_content(reaction, count),
            type: :submit,
            class: reaction_button_classes(user_reacted),
            title: reaction_title(reaction, user_reacted),
            data: { vote_fu_reactions_target: "reaction" }
          )
        ])
      end
    end

    def readonly_reaction(reaction, count)
      tag.span(
        reaction_content(reaction, count),
        class: "vote-fu-reaction vote-fu-reaction--readonly",
        title: reaction[:label]
      )
    end

    def reaction_content(reaction, count)
      parts = [tag.span(reaction[:emoji], class: "vote-fu-reaction-emoji")]
      parts << tag.span(count.to_s, class: "vote-fu-reaction-count") if @show_counts && count.positive?

      if @show_users && count.positive?
        parts << tag.span(
          reaction_users(reaction[:scope]),
          class: "vote-fu-reaction-users"
        )
      end

      safe_join(parts)
    end

    def reaction_wrapper_classes(user_reacted, count)
      classes = ["vote-fu-reaction-wrapper"]
      classes << "vote-fu-reaction-wrapper--active" if user_reacted
      classes << "vote-fu-reaction-wrapper--empty" if count.zero?
      classes.join(" ")
    end

    def reaction_button_classes(user_reacted)
      classes = ["vote-fu-reaction"]
      classes << "vote-fu-reaction--active" if user_reacted
      classes.join(" ")
    end

    def reaction_title(reaction, user_reacted)
      if user_reacted
        "Remove #{reaction[:label]} reaction"
      else
        "React with #{reaction[:label]}"
      end
    end

    def add_reaction_button
      tag.div(class: "vote-fu-add-reaction") do
        tag.button(
          "➕",
          class: "vote-fu-add-reaction-btn",
          title: "Add reaction",
          data: {
            action: "click->vote-fu-reactions#showPicker",
            vote_fu_reactions_target: "addButton"
          }
        )
      end
    end

    def turbo_form_data
      { turbo_stream: true, action: "submit->vote-fu-reactions#toggle" }
    end

    def reaction_count(scope)
      @reaction_counts ||= {}
      @reaction_counts[scope] ||= @voteable.votes_for(scope: scope)
    end

    def user_reacted?(scope)
      return false unless @voter

      @user_reactions ||= {}
      @user_reactions[scope] ||= @voteable.voted_by?(@voter, scope: scope)
    end

    def reaction_users(scope)
      voters = @voteable.voters_for(scope: scope).limit(@max_users)
      names = voters.map { |v| v.try(:name) || v.try(:username) || "Someone" }

      remaining = reaction_count(scope) - names.size
      names << "#{remaining} more" if remaining.positive?

      names.join(", ")
    end

    def toggle_path
      VoteFu::Engine.routes.url_helpers.toggle_votes_path
    end

    def dom_id(suffix)
      "vote_fu_#{@voteable.model_name.singular}_#{@voteable.id}_#{suffix}"
    end
  end
end
