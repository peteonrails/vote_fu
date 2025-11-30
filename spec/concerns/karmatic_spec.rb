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

      it "subtracts downvotes with default weight" do
        voter1.upvote(post1)
        voter2.downvote(post1)

        expect(author.karma).to eq 0
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

    it "includes recent karma" do
      voter1.upvote(post)

      breakdown = author.karma_breakdown
      expect(breakdown.first[:recent]).to eq 1
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

  describe "#karma_level" do
    let!(:post) { Post.create!(title: "Post", user: author) }

    it "returns Newcomer for 0 karma" do
      expect(author.karma_level).to eq "Newcomer"
    end

    it "returns Contributor for 10+ karma" do
      10.times { User.create!(name: "v").upvote(post) }
      expect(author.karma_level).to eq "Contributor"
    end

    it "returns Active for 50+ karma" do
      50.times { User.create!(name: "v").upvote(post) }
      expect(author.karma_level).to eq "Active"
    end
  end

  describe "#karma_progress" do
    let!(:post) { Post.create!(title: "Post", user: author) }

    it "returns progress to next level" do
      5.times { User.create!(name: "v").upvote(post) }

      progress = author.karma_progress
      expect(progress[:current_level]).to eq "Newcomer"
      expect(progress[:next_level]).to eq "Contributor"
      expect(progress[:karma_needed]).to eq 5
      expect(progress[:progress]).to eq 50.0
    end

    it "returns 100% progress at max level" do
      1000.times { User.create!(name: "v").upvote(post) }

      progress = author.karma_progress
      expect(progress[:current_level]).to eq "Legend"
      expect(progress[:next_level]).to be_nil
      expect(progress[:progress]).to eq 100.0
    end
  end

  describe "#karma_level?" do
    let!(:post) { Post.create!(title: "Post", user: author) }

    it "returns true if user has level" do
      10.times { User.create!(name: "v").upvote(post) }
      expect(author.karma_level?("Contributor")).to be true
    end

    it "returns false if user doesn't have level" do
      expect(author.karma_level?("Expert")).to be false
    end
  end

  describe "#recent_karma" do
    let!(:post) { Post.create!(title: "Post", user: author) }

    it "only counts votes within time window" do
      voter1.upvote(post)

      expect(author.recent_karma(days: 30)).to eq 1
      expect(author.recent_karma(days: 7)).to eq 1
    end
  end
end
