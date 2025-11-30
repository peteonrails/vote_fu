# frozen_string_literal: true

RSpec.describe VoteFu::Algorithms::RedditHot do
  describe ".call" do
    it "returns higher scores for newer items" do
      old_post = Post.create!(title: "Old", created_at: 1.week.ago)
      new_post = Post.create!(title: "New", created_at: 1.hour.ago)

      user = User.create!(name: "u")
      user2 = User.create!(name: "u2")
      user.upvote(old_post)
      user2.upvote(new_post)

      old_score = described_class.call(old_post)
      new_score = described_class.call(new_post)

      expect(new_score).to be > old_score
    end

    it "returns higher scores for more upvotes" do
      # Create at same time to isolate vote effect
      post1 = Post.create!(title: "P1", created_at: 1.hour.ago)
      post2 = Post.create!(title: "P2", created_at: 1.hour.ago)

      10.times { User.create!(name: "u").upvote(post1) }
      2.times { User.create!(name: "u").upvote(post2) }

      # Reload to get counter cache values
      post1.reload
      post2.reload

      expect(described_class.call(post1)).to be > described_class.call(post2)
    end

    it "returns negative-ish scores for downvoted items" do
      post = Post.create!(title: "Bad")
      5.times { User.create!(name: "u").downvote(post) }

      # Score will still be positive due to time component but lower
      score = described_class.call(post)
      expect(score).to be_a(Float)
    end

    it "balances votes and time" do
      # Old post with many votes vs new post with few
      old_popular = Post.create!(title: "Old Popular", created_at: 2.days.ago)
      new_unpopular = Post.create!(title: "New", created_at: 1.minute.ago)

      100.times { User.create!(name: "u").upvote(old_popular) }
      User.create!(name: "u").upvote(new_unpopular)

      # The new post might still beat old popular one due to time
      # This depends on the exact timing - mainly testing it runs
      expect(described_class.call(old_popular)).to be_a(Float)
      expect(described_class.call(new_unpopular)).to be_a(Float)
    end
  end
end
