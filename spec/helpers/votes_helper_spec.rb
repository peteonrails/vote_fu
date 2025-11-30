# frozen_string_literal: true

require "spec_helper"
require_relative "../../app/helpers/vote_fu/votes_helper"

RSpec.describe VoteFu::VotesHelper do
  # Create a test class that includes the helper
  let(:helper_class) do
    Class.new do
      include VoteFu::VotesHelper

      attr_accessor :test_current_user

      def render(partial:, locals:)
        { partial: partial, locals: locals }
      end

      private

      def current_user
        @test_current_user
      end
    end
  end

  let(:helper) { helper_class.new }

  let(:user) { User.create!(name: "Test User") }
  let(:post) { Post.create!(title: "Test Post") }

  describe "#vote_dom_id" do
    it "returns correct DOM ID without scope" do
      expect(helper.vote_dom_id(post, :widget)).to eq "vote_fu_post_#{post.id}_widget"
    end

    it "returns correct DOM ID with scope" do
      expect(helper.vote_dom_id(post, :count, scope: :quality)).to eq "vote_fu_post_#{post.id}_quality_count"
    end

    it "returns correct DOM ID for different suffixes" do
      expect(helper.vote_dom_id(post, :error)).to eq "vote_fu_post_#{post.id}_error"
    end
  end

  describe "#voted_on?" do
    before { helper.test_current_user = user }

    it "returns false when not voted" do
      expect(helper.voted_on?(post)).to be false
    end

    it "returns true when voted" do
      user.upvote(post)
      expect(helper.voted_on?(post)).to be true
    end

    it "checks direction" do
      user.upvote(post)
      expect(helper.voted_on?(post, direction: :up)).to be true
      expect(helper.voted_on?(post, direction: :down)).to be false
    end

    it "returns false when no voter" do
      helper.test_current_user = nil
      expect(helper.voted_on?(post)).to be false
    end
  end

  describe "#current_vote_direction" do
    before { helper.test_current_user = user }

    it "returns nil when not voted" do
      expect(helper.current_vote_direction(post)).to be_nil
    end

    it "returns :up for upvote" do
      user.upvote(post)
      expect(helper.current_vote_direction(post)).to eq :up
    end

    it "returns :down for downvote" do
      user.downvote(post)
      expect(helper.current_vote_direction(post)).to eq :down
    end
  end

  describe "#vote_widget" do
    before { helper.test_current_user = user }

    it "returns render params for widget partial" do
      result = helper.vote_widget(post)

      expect(result[:partial]).to eq "vote_fu/votes/widget"
      expect(result[:locals][:voteable]).to eq post
      expect(result[:locals][:voter]).to eq user
    end

    it "passes scope option" do
      result = helper.vote_widget(post, scope: :quality)
      expect(result[:locals][:scope]).to eq :quality
    end

    it "passes custom labels" do
      result = helper.vote_widget(post, upvote_label: "👍", downvote_label: "👎")
      expect(result[:locals][:upvote_label]).to eq "👍"
      expect(result[:locals][:downvote_label]).to eq "👎"
    end
  end

  describe "#vote_count" do
    it "returns render params for count partial" do
      result = helper.vote_count(post)

      expect(result[:partial]).to eq "vote_fu/votes/count"
      expect(result[:locals][:voteable]).to eq post
    end

    it "passes format option" do
      result = helper.vote_count(post, format: :percentage)
      expect(result[:locals][:format]).to eq :percentage
    end
  end

  describe "#like_button" do
    before { helper.test_current_user = user }

    it "returns render params for like button partial" do
      result = helper.like_button(post)

      expect(result[:partial]).to eq "vote_fu/votes/like_button"
      expect(result[:locals][:voteable]).to eq post
    end

    it "passes custom labels" do
      result = helper.like_button(post, liked_label: "❤️", unliked_label: "🤍")
      expect(result[:locals][:liked_label]).to eq "❤️"
      expect(result[:locals][:unliked_label]).to eq "🤍"
    end
  end

  describe "#upvote_button" do
    before { helper.test_current_user = user }

    it "returns render params for upvote button partial" do
      result = helper.upvote_button(post)

      expect(result[:partial]).to eq "vote_fu/votes/upvote_button"
    end
  end

  describe "#downvote_button" do
    before { helper.test_current_user = user }

    it "returns render params for downvote button partial" do
      result = helper.downvote_button(post)

      expect(result[:partial]).to eq "vote_fu/votes/downvote_button"
    end
  end
end
