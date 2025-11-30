# VoteFu

**The original Rails voting gem, reborn for the modern era.**

VoteFu was first released in 2008 for Rails 2. Over the years it was forked countless times—most notably as ThumbsUp—as the Rails ecosystem evolved and the original fell behind. While the forks kept pace with Rails 3, 4, and 5, none made the leap to embrace Hotwire.

VoteFu 2.0 changes that. This is a complete ground-up rewrite that leapfrogs every fork with first-class Turbo Streams, ViewComponents, Stimulus controllers, and ActionCable support. No more bolting modern UI onto legacy architecture. VoteFu is back, and it's ready for Rails 8.

## Features

- **Flexible voting**: Up/down votes, star ratings (1-5), weighted votes
- **Scoped voting**: Multiple voting contexts per item (quality, helpfulness, etc.)
- **Counter caches**: Automatic vote count maintenance for performance
- **Ranking algorithms**: Wilson Score, Reddit Hot, Hacker News built-in
- **Karma system**: Calculate user reputation from votes on their content
- **Turbo-native**: Turbo Streams responses out of the box
- **Modern Rails**: Designed for Rails 8+, uses Concerns, no legacy patterns

## Installation

Add to your Gemfile:

```ruby
gem 'vote_fu', '~> 2.0'
```

Run the installer:

```bash
rails generate vote_fu:install
rails db:migrate
```

## Quick Start

### Set up your models

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  acts_as_voteable
end

# app/models/user.rb
class User < ApplicationRecord
  acts_as_voter
end
```

### Cast votes

```ruby
user.upvote(post)           # +1 vote
user.downvote(post)         # -1 vote
user.vote_on(post, value: 5) # 5-star rating
user.unvote(post)           # Remove vote
user.toggle_vote(post)      # Toggle on/off
```

### Query votes

```ruby
# On voteables
post.votes_for              # Upvote count
post.votes_against          # Downvote count
post.plusminus              # Net score
post.wilson_score           # Ranking score (0.0-1.0)
post.voted_by?(user)        # Did user vote?

# On voters
user.voted_on?(post)        # Did user vote?
user.vote_value_for(post)   # What value?
user.voted_items(Post)      # All posts user voted on
```

### Rank items

```ruby
Post.by_votes               # Order by vote total
Post.by_wilson_score        # Order by Wilson Score
Post.trending               # Most votes in 24h
Post.with_positive_score    # Net positive only
```

## Scoped Voting

Allow multiple independent votes per item:

```ruby
# User can vote separately on quality and helpfulness
user.vote_on(review, value: 5, scope: :quality)
user.vote_on(review, value: 1, scope: :helpfulness)

review.plusminus(scope: :quality)      # => 5
review.plusminus(scope: :helpfulness)  # => 1
```

## Karma

Calculate user reputation:

```ruby
class User < ApplicationRecord
  has_many :posts

  acts_as_voter
  has_karma :posts, as: :author
end

user.karma  # Sum of upvotes on user's posts
```

## Counter Caches

Add columns for performance:

```ruby
# Migration
add_column :posts, :votes_count, :integer, default: 0
add_column :posts, :votes_total, :integer, default: 0
add_column :posts, :upvotes_count, :integer, default: 0
add_column :posts, :downvotes_count, :integer, default: 0
```

Counters update automatically when `counter_cache: true` (default).

## Ranking Algorithms

### Wilson Score
Best for quality ranking. Accounts for statistical confidence.
```ruby
post.wilson_score(confidence: 0.95)
```

### Reddit Hot
Balances popularity with recency.
```ruby
post.hot_score(gravity: 1.8)
```

### Hacker News
Heavily favors recent content.
```ruby
VoteFu::Algorithms::HackerNews.call(post, gravity: 1.8)
```

## Turbo Integration

VoteFu comes with Turbo Streams support out of the box.

### View Helpers

```erb
<%# Reddit-style upvote/downvote widget %>
<%= vote_widget @post %>

<%# Simple like button %>
<%= like_button @photo %>

<%# Scoped voting %>
<%= vote_widget @review, scope: :quality %>
<%= vote_widget @review, scope: :helpfulness %>
```

### ViewComponents

For more control, use the ViewComponents directly:

```erb
<%# Vote widget with all options %>
<%= render VoteFu::VoteWidgetComponent.new(
  voteable: @post,
  voter: current_user,
  variant: :vertical,
  upvote_label: "👍",
  downvote_label: "👎"
) %>

<%# Star rating %>
<%= render VoteFu::StarRatingComponent.new(
  voteable: @product,
  voter: current_user,
  show_average: true,
  show_count: true
) %>

<%# Emoji reactions (Slack/GitHub style) %>
<%= render VoteFu::ReactionBarComponent.new(
  voteable: @comment,
  voter: current_user,
  reactions: [
    { emoji: "👍", label: "Like", scope: "like" },
    { emoji: "❤️", label: "Love", scope: "love" },
    { emoji: "🎉", label: "Celebrate", scope: "celebrate" }
  ]
) %>
```

### Controller

VoteFu provides a complete controller for handling votes:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount VoteFu::Engine => "/vote_fu"
end
```

The controller responds to:
- `POST /vote_fu/votes` - Create/update a vote
- `POST /vote_fu/votes/toggle` - Toggle vote (upvote ↔ remove)
- `DELETE /vote_fu/votes/:id` - Remove a vote

All endpoints return Turbo Streams for seamless updates.

## Styles

Import the default styles:

```css
/* app/assets/stylesheets/application.css */
@import "vote_fu/votes";
```

Or use CSS variables to customize:

```css
:root {
  --vote-fu-upvote-color: #ff6314;
  --vote-fu-downvote-color: #7193ff;
  --vote-fu-like-color: #e0245e;
}
```

## Configuration

```ruby
# config/initializers/vote_fu.rb
VoteFu.configure do |config|
  config.allow_recast = true           # Change votes?
  config.allow_duplicate_votes = false # Multiple votes per user?
  config.allow_self_vote = false       # Vote on yourself?
  config.counter_cache = true          # Auto-update counters?
  config.turbo_broadcasts = true       # Turbo Stream broadcasts?
  config.default_ranking = :wilson_score
  config.hot_ranking_gravity = 1.8
end
```

## History

VoteFu was created in 2008 when Rails 2 was cutting-edge. It became one of the go-to voting solutions for Rails applications, powering upvotes, ratings, and karma systems across thousands of apps.

When Rails 3 arrived with breaking changes, VoteFu fell behind. In 2010, it was forked as [ThumbsUp](https://github.com/bouchard/thumbs_up), which carried the torch through Rails 3, 4, 5, and beyond. Other forks emerged too—acts_as_votable, votable, and more—each taking the original idea in different directions.

But none of them embraced Hotwire. As Rails evolved toward Turbo and Stimulus, the voting gem ecosystem stayed stuck in the jQuery era, requiring manual JavaScript for real-time updates.

**VoteFu 2.0 is a complete rewrite.** Zero legacy code. Built from scratch for Rails 7.2+ with Turbo Streams, ViewComponents, and ActionCable baked in. The original is back—and it's leapfrogged every fork.

## License

MIT License. See [LICENSE](MIT-LICENSE).
