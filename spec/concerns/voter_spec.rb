# frozen_string_literal: true

RSpec.describe VoteFu::Concerns::Voter do
  let(:user) { User.create!(name: "Test User") }
  let(:post) { Post.create!(title: "Test Post") }

  describe "#vote_on" do
    it "creates a vote with the specified value" do
      vote = user.vote_on(post, value: 1)

      expect(vote).to be_persisted
      expect(vote.value).to eq 1
      expect(vote.voter).to eq user
      expect(vote.voteable).to eq post
    end

    it "creates votes with different values" do
      vote = user.vote_on(post, value: 5)
      expect(vote.value).to eq 5
    end

    it "creates scoped votes" do
      vote = user.vote_on(post, value: 1, scope: :quality)
      expect(vote.scope).to eq "quality"
    end

    context "when recasting is allowed" do
      before { VoteFu.configuration.allow_recast = true }

      it "updates existing vote" do
        user.vote_on(post, value: 1)
        updated = user.vote_on(post, value: -1)

        expect(VoteFu::Vote.count).to eq 1
        expect(updated.value).to eq(-1)
      end
    end

    context "when recasting is not allowed" do
      before { VoteFu.configuration.allow_recast = false }

      it "raises AlreadyVotedError" do
        user.vote_on(post, value: 1)

        expect { user.vote_on(post, value: -1) }
          .to raise_error(VoteFu::AlreadyVotedError)
      end
    end

    context "when self-voting is not allowed" do
      before { VoteFu.configuration.allow_self_vote = false }

      it "raises SelfVoteError" do
        # User voting on itself (if User was also voteable)
        # This test demonstrates the concept
        expect { user.vote_on(user, value: 1) }
          .to raise_error(VoteFu::SelfVoteError)
      end
    end

    it "raises InvalidVoteValueError for non-integer values" do
      expect { user.vote_on(post, value: "up") }
        .to raise_error(VoteFu::InvalidVoteValueError)
    end
  end

  describe "#upvote" do
    it "creates a vote with value 1" do
      vote = user.upvote(post)
      expect(vote.value).to eq 1
    end
  end

  describe "#downvote" do
    it "creates a vote with value -1" do
      vote = user.downvote(post)
      expect(vote.value).to eq(-1)
    end
  end

  describe "#unvote" do
    it "removes the vote" do
      user.upvote(post)
      expect { user.unvote(post) }.to change(VoteFu::Vote, :count).by(-1)
    end

    it "returns the destroyed vote" do
      user.upvote(post)
      result = user.unvote(post)
      expect(result).to be_destroyed
    end

    it "returns nil if no vote exists" do
      expect(user.unvote(post)).to be_nil
    end

    it "only removes the vote with matching scope" do
      user.vote_on(post, value: 1, scope: :quality)
      user.vote_on(post, value: 1, scope: :helpfulness)

      user.unvote(post, scope: :quality)

      expect(user.voted_on?(post, scope: :quality)).to be false
      expect(user.voted_on?(post, scope: :helpfulness)).to be true
    end
  end

  describe "#toggle_vote" do
    it "creates a vote if none exists" do
      expect { user.toggle_vote(post) }.to change(VoteFu::Vote, :count).by(1)
    end

    it "removes the vote if one exists" do
      user.upvote(post)
      expect { user.toggle_vote(post) }.to change(VoteFu::Vote, :count).by(-1)
    end
  end

  describe "#voted_on?" do
    it "returns false when no vote exists" do
      expect(user.voted_on?(post)).to be false
    end

    it "returns true when a vote exists" do
      user.upvote(post)
      expect(user.voted_on?(post)).to be true
    end

    it "checks direction :up" do
      user.upvote(post)
      expect(user.voted_on?(post, direction: :up)).to be true
      expect(user.voted_on?(post, direction: :down)).to be false
    end

    it "checks direction :down" do
      user.downvote(post)
      expect(user.voted_on?(post, direction: :down)).to be true
      expect(user.voted_on?(post, direction: :up)).to be false
    end

    it "checks specific value" do
      user.vote_on(post, value: 5)
      expect(user.voted_on?(post, direction: 5)).to be true
      expect(user.voted_on?(post, direction: 3)).to be false
    end

    it "respects scope" do
      user.vote_on(post, value: 1, scope: :quality)
      expect(user.voted_on?(post, scope: :quality)).to be true
      expect(user.voted_on?(post, scope: :helpfulness)).to be false
      expect(user.voted_on?(post)).to be false # unscoped
    end
  end

  describe "#vote_value_for" do
    it "returns the vote value" do
      user.vote_on(post, value: 5)
      expect(user.vote_value_for(post)).to eq 5
    end

    it "returns nil when no vote exists" do
      expect(user.vote_value_for(post)).to be_nil
    end
  end

  describe "#vote_direction_for" do
    it "returns :up for positive votes" do
      user.upvote(post)
      expect(user.vote_direction_for(post)).to eq :up
    end

    it "returns :down for negative votes" do
      user.downvote(post)
      expect(user.vote_direction_for(post)).to eq :down
    end

    it "returns nil when no vote exists" do
      expect(user.vote_direction_for(post)).to be_nil
    end
  end

  describe "#voted_items" do
    it "returns all items the user voted on" do
      post2 = Post.create!(title: "Post 2")
      post3 = Post.create!(title: "Post 3")

      user.upvote(post)
      user.downvote(post2)

      expect(user.voted_items(Post)).to contain_exactly(post, post2)
      expect(user.voted_items(Post)).not_to include(post3)
    end
  end

  describe "#vote_count" do
    before do
      post2 = Post.create!(title: "Post 2")
      post3 = Post.create!(title: "Post 3")

      user.upvote(post)
      user.upvote(post2)
      user.downvote(post3)
    end

    it "returns total vote count" do
      expect(user.vote_count).to eq 3
    end

    it "returns upvote count" do
      expect(user.vote_count(:up)).to eq 2
    end

    it "returns downvote count" do
      expect(user.vote_count(:down)).to eq 1
    end
  end

  describe "dynamic methods from votes_on" do
    it "generates upvote_post method" do
      expect(user).to respond_to(:upvote_post)
      user.upvote_post(post)
      expect(user.voted_on?(post, direction: :up)).to be true
    end

    it "generates downvote_post method" do
      expect(user).to respond_to(:downvote_post)
      user.downvote_post(post)
      expect(user.voted_on?(post, direction: :down)).to be true
    end

    it "generates unvote_post method" do
      user.upvote_post(post)
      user.unvote_post(post)
      expect(user.voted_on?(post)).to be false
    end

    it "generates voted_on_post? method" do
      expect(user.voted_on_post?(post)).to be false
      user.upvote_post(post)
      expect(user.voted_on_post?(post)).to be true
    end

    it "generates vote_value_for_post method" do
      user.vote_on_post(post, value: 5)
      expect(user.vote_value_for_post(post)).to eq 5
    end
  end
end
