# frozen_string_literal: true

RSpec.describe VoteFu::Algorithms::WilsonScore do
  let(:post) { Post.create!(title: "Test") }

  def add_votes(up:, down:)
    up.times { User.create!(name: "u").upvote(post) }
    down.times { User.create!(name: "u").downvote(post) }
  end

  describe ".call" do
    it "returns 0 for items with no votes" do
      expect(described_class.call(post)).to eq 0.0
    end

    it "returns a score between 0 and 1" do
      add_votes(up: 10, down: 2)
      score = described_class.call(post)

      expect(score).to be_between(0.0, 1.0)
    end

    it "returns higher scores for more upvotes" do
      add_votes(up: 100, down: 10)
      high_score = described_class.call(post)

      post2 = Post.create!(title: "P2")
      10.times { User.create!(name: "u").upvote(post2) }
      2.times { User.create!(name: "u").downvote(post2) }
      low_score = described_class.call(post2)

      # More total votes with similar ratio should have higher confidence
      expect(high_score).to be > low_score
    end

    it "penalizes items with few votes even if all positive" do
      add_votes(up: 1, down: 0)
      few_votes = described_class.call(post)

      post2 = Post.create!(title: "P2")
      100.times { User.create!(name: "u").upvote(post2) }
      many_votes = described_class.call(post2)

      expect(many_votes).to be > few_votes
    end

    it "accepts different confidence levels" do
      add_votes(up: 50, down: 10)

      score_95 = described_class.call(post, confidence: 0.95)
      score_80 = described_class.call(post, confidence: 0.80)

      # Lower confidence = higher score (less conservative)
      expect(score_80).to be > score_95
    end
  end
end
