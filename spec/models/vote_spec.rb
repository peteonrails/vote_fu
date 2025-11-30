# frozen_string_literal: true

RSpec.describe VoteFu::Vote do
  let(:user) { User.create!(name: "Test User") }
  let(:post) { Post.create!(title: "Test Post") }

  describe "validations" do
    it "requires a value" do
      vote = described_class.new(voter: user, voteable: post, value: nil)
      expect(vote).not_to be_valid
      expect(vote.errors[:value]).to include("can't be blank")
    end

    it "requires value to be an integer" do
      vote = described_class.new(voter: user, voteable: post, value: 1.5)
      expect(vote).not_to be_valid
    end

    it "allows integer values" do
      vote = described_class.new(voter: user, voteable: post, value: 5)
      expect(vote).to be_valid
    end

    context "when duplicate votes are not allowed" do
      before { VoteFu.configuration.allow_duplicate_votes = false }

      it "prevents duplicate votes" do
        described_class.create!(voter: user, voteable: post, value: 1)
        duplicate = described_class.new(voter: user, voteable: post, value: -1)

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:voter_id]).to include("has already voted on this item")
      end

      it "allows votes with different scopes" do
        described_class.create!(voter: user, voteable: post, value: 1, scope: "quality")
        different_scope = described_class.new(voter: user, voteable: post, value: 1, scope: "helpfulness")

        expect(different_scope).to be_valid
      end
    end

    context "when duplicate votes are allowed" do
      before { VoteFu.configuration.allow_duplicate_votes = true }

      it "allows duplicate votes" do
        described_class.create!(voter: user, voteable: post, value: 1)
        duplicate = described_class.new(voter: user, voteable: post, value: 1)

        expect(duplicate).to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:upvote) { described_class.create!(voter: user, voteable: post, value: 1) }
    let(:other_user) { User.create!(name: "Other") }
    let!(:downvote) { described_class.create!(voter: other_user, voteable: post, value: -1) }

    describe ".up" do
      it "returns only positive votes" do
        expect(described_class.up).to contain_exactly(upvote)
      end
    end

    describe ".down" do
      it "returns only negative votes" do
        expect(described_class.down).to contain_exactly(downvote)
      end
    end

    describe ".for_voter" do
      it "returns votes by a specific voter" do
        expect(described_class.for_voter(user)).to contain_exactly(upvote)
      end
    end

    describe ".for_voteable" do
      it "returns votes on a specific voteable" do
        other_post = Post.create!(title: "Other")
        other_vote = described_class.create!(voter: user, voteable: other_post, value: 1)

        expect(described_class.for_voteable(post)).to contain_exactly(upvote, downvote)
        expect(described_class.for_voteable(other_post)).to contain_exactly(other_vote)
      end
    end

    describe ".with_scope" do
      let!(:scoped_vote) do
        third_user = User.create!(name: "Third")
        described_class.create!(voter: third_user, voteable: post, value: 1, scope: "quality")
      end

      it "returns votes with a specific scope" do
        expect(described_class.with_scope("quality")).to contain_exactly(scoped_vote)
      end

      it "returns unscoped votes when scope is nil" do
        expect(described_class.with_scope(nil)).to contain_exactly(upvote, downvote)
      end
    end
  end

  describe "#up?" do
    it "returns true for positive values" do
      vote = described_class.new(value: 1)
      expect(vote.up?).to be true
    end

    it "returns false for negative values" do
      vote = described_class.new(value: -1)
      expect(vote.up?).to be false
    end

    it "returns false for zero" do
      vote = described_class.new(value: 0)
      expect(vote.up?).to be false
    end
  end

  describe "#down?" do
    it "returns true for negative values" do
      vote = described_class.new(value: -1)
      expect(vote.down?).to be true
    end

    it "returns false for positive values" do
      vote = described_class.new(value: 1)
      expect(vote.down?).to be false
    end
  end

  describe "#direction" do
    it "returns :up for positive values" do
      expect(described_class.new(value: 1).direction).to eq :up
    end

    it "returns :down for negative values" do
      expect(described_class.new(value: -1).direction).to eq :down
    end

    it "returns :neutral for zero" do
      expect(described_class.new(value: 0).direction).to eq :neutral
    end
  end
end
