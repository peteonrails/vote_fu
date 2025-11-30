# frozen_string_literal: true

RSpec.describe VoteFu::Concerns::Voteable do
  let(:user) { User.create!(name: "Test User") }
  let(:user2) { User.create!(name: "User 2") }
  let(:user3) { User.create!(name: "User 3") }
  let(:post) { Post.create!(title: "Test Post") }

  describe "associations" do
    it "has many received_votes" do
      expect(post).to respond_to(:received_votes)
      expect(post.received_votes).to eq []
    end
  end

  describe "#votes_for" do
    it "returns count of upvotes" do
      user.upvote(post)
      user2.upvote(post)
      user3.downvote(post)

      expect(post.votes_for).to eq 2
    end

    it "respects scope" do
      user.vote_on(post, value: 1, scope: :quality)
      user2.vote_on(post, value: 1, scope: :helpfulness)

      expect(post.votes_for(scope: :quality)).to eq 1
    end
  end

  describe "#votes_against" do
    it "returns count of downvotes" do
      user.upvote(post)
      user2.downvote(post)
      user3.downvote(post)

      expect(post.votes_against).to eq 2
    end
  end

  describe "#votes_count" do
    it "returns total vote count" do
      user.upvote(post)
      user2.downvote(post)

      expect(post.votes_count).to eq 2
    end
  end

  describe "#votes_total" do
    it "returns sum of vote values" do
      user.vote_on(post, value: 5)
      user2.vote_on(post, value: 3)
      user3.vote_on(post, value: -1)

      expect(post.votes_total).to eq 7
    end
  end

  describe "#plusminus" do
    it "returns upvotes minus downvotes" do
      user.upvote(post)
      user2.upvote(post)
      user3.downvote(post)

      # Reload to get fresh counter cache values
      post.reload
      expect(post.plusminus).to eq 1
    end

    it "uses counter cache if available" do
      post.update_column(:votes_total, 42)
      expect(post.plusminus).to eq 42
    end
  end

  describe "#percent_for" do
    it "returns percentage of upvotes" do
      user.upvote(post)
      user2.upvote(post)
      user3.downvote(post)

      expect(post.percent_for).to eq 66.7
    end

    it "returns 0 when no votes" do
      expect(post.percent_for).to eq 0.0
    end
  end

  describe "#percent_against" do
    it "returns percentage of downvotes" do
      user.upvote(post)
      user2.downvote(post)

      expect(post.percent_against).to eq 50.0
    end
  end

  describe "#voted_by?" do
    it "returns false when user hasn't voted" do
      expect(post.voted_by?(user)).to be false
    end

    it "returns true when user has voted" do
      user.upvote(post)
      expect(post.voted_by?(user)).to be true
    end

    it "checks direction" do
      user.upvote(post)
      expect(post.voted_by?(user, direction: :up)).to be true
      expect(post.voted_by?(user, direction: :down)).to be false
    end
  end

  describe "#voters" do
    it "returns users who voted" do
      user.upvote(post)
      user2.downvote(post)

      expect(post.voters).to contain_exactly(user, user2)
    end
  end

  describe "#voters_for" do
    it "returns users who upvoted" do
      user.upvote(post)
      user2.downvote(post)

      expect(post.voters_for).to contain_exactly(user)
    end
  end

  describe "#voters_against" do
    it "returns users who downvoted" do
      user.upvote(post)
      user2.downvote(post)

      expect(post.voters_against).to contain_exactly(user2)
    end
  end

  describe "class methods" do
    let!(:popular) do
      p = Post.create!(title: "Popular")
      5.times { User.create!(name: "u").upvote(p) }
      p
    end

    let!(:controversial) do
      p = Post.create!(title: "Controversial")
      User.create!(name: "a").upvote(p)
      User.create!(name: "b").downvote(p)
      p
    end

    let!(:unpopular) do
      p = Post.create!(title: "Unpopular")
      3.times { User.create!(name: "u").downvote(p) }
      p
    end

    describe ".by_votes" do
      it "orders by vote total descending by default" do
        result = Post.by_votes.to_a
        expect(result.first).to eq popular
        expect(result.last).to eq unpopular
      end

      it "orders ascending when specified" do
        result = Post.by_votes(:asc).to_a
        expect(result.first).to eq unpopular
      end
    end

    describe ".with_positive_score" do
      it "returns only items with positive net votes" do
        result = Post.with_positive_score
        expect(result).to include(popular)
        expect(result).not_to include(unpopular)
      end
    end

    describe ".with_votes" do
      it "returns items that have votes" do
        empty = Post.create!(title: "Empty")
        result = Post.with_votes

        expect(result).to include(popular, controversial, unpopular)
        expect(result).not_to include(empty)
      end
    end

    describe ".without_votes" do
      it "returns items without any votes" do
        empty = Post.create!(title: "Empty")
        result = Post.without_votes

        expect(result).to contain_exactly(empty, post)
      end
    end
  end

  describe "counter cache" do
    before { VoteFu.configuration.counter_cache = true }

    it "increments votes_count on create" do
      expect { user.upvote(post) }
        .to change { post.reload.votes_count }.from(0).to(1)
    end

    it "increments votes_total on create" do
      expect { user.upvote(post) }
        .to change { post.reload.votes_total }.from(0).to(1)
    end

    it "increments upvotes_count for positive votes" do
      expect { user.upvote(post) }
        .to change { post.reload.upvotes_count }.from(0).to(1)
    end

    it "increments downvotes_count for negative votes" do
      expect { user.downvote(post) }
        .to change { post.reload.downvotes_count }.from(0).to(1)
    end

    it "decrements counters on destroy" do
      user.upvote(post)
      expect { user.unvote(post) }
        .to change { post.reload.votes_count }.from(1).to(0)
    end

    it "updates counters when vote value changes" do
      VoteFu.configuration.allow_recast = true
      user.upvote(post)

      expect { user.downvote(post) }
        .to change { post.reload.votes_total }.from(1).to(-1)
        .and change { post.reload.upvotes_count }.from(1).to(0)
        .and change { post.reload.downvotes_count }.from(0).to(1)
    end
  end
end
