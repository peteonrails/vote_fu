# frozen_string_literal: true

RSpec.describe VoteFu::Concerns::Karmatic do
  let(:author) { User.create!(name: "Author") }
  let(:voter1) { User.create!(name: "Voter 1") }
  let(:voter2) { User.create!(name: "Voter 2") }
  let(:voter3) { User.create!(name: "Voter 3") }

  describe "#karma" do
    context "with posts" do
      let!(:post1) { Post.create!(title: "Post 1", user: author) }
      let!(:post2) { Post.create!(title: "Post 2", user: author) }

      it "returns 0 when no votes" do
        expect(author.karma).to eq 0
      end

      it "counts upvotes on owned content" do
        voter1.upvote(post1)
        voter2.upvote(post1)
        voter3.upvote(post2)

        expect(author.karma).to eq 3
      end

      it "ignores downvotes by default (weight 1.0)" do
        voter1.upvote(post1)
        voter2.downvote(post1)

        # Default weight is [1.0], so downvotes don't subtract
        expect(author.karma).to eq 1
      end

      it "doesn't count votes on other users' content" do
        other_author = User.create!(name: "Other")
        other_post = Post.create!(title: "Other Post", user: other_author)

        voter1.upvote(post1)
        voter2.upvote(other_post)

        expect(author.karma).to eq 1
      end
    end
  end

  describe "#karma_breakdown" do
    let!(:post) { Post.create!(title: "Post", user: author) }

    it "returns breakdown by source" do
      voter1.upvote(post)

      breakdown = author.karma_breakdown
      expect(breakdown).to be_an(Array)
      expect(breakdown.first[:source]).to eq :posts
      expect(breakdown.first[:value]).to eq 1
    end
  end

  describe "#karma_for" do
    let!(:post) { Post.create!(title: "Post", user: author) }

    it "returns karma for specific source" do
      voter1.upvote(post)
      voter2.upvote(post)

      expect(author.karma_for(:posts)).to eq 2
    end

    it "returns 0 for unknown source" do
      expect(author.karma_for(:unknown)).to eq 0
    end
  end
end
