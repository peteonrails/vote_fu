# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.1] - 2024-11-30

### Changed
- Added legacy VoteFu contributors to gem authors
- Fixed gemspec homepage to point to votefu.dev

## [2.0.0] - 2024-11-29

Complete rewrite of VoteFu for modern Rails applications.

### Added

#### Core Voting
- Integer vote values (supports up/down, star ratings 1-5, weighted votes)
- Scoped voting - multiple independent vote contexts per voteable
- Counter cache support (`votes_count`, `votes_total`, `upvotes_count`, `downvotes_count`)
- `acts_as_voteable` and `acts_as_voter` concerns
- `votes_on` DSL for dynamic method generation
- `voteable_by` DSL for explicit voter relationships

#### Algorithms (Built-in, No External Dependencies)
- **Wilson Score Lower Bound** - Statistical confidence interval for quality ranking
- **Reddit Hot** - Time-decaying popularity ranking
- **Hacker News** - Heavily time-weighted ranking

#### Turbo/Hotwire Integration
- `VotesController` with full Turbo Stream responses
- View helpers: `vote_widget`, `like_button`, `upvote_button`, `downvote_button`, `vote_count`
- Turbo Stream partials for seamless DOM updates
- Stimulus controller for optimistic UI updates

#### ViewComponents
- `VoteWidgetComponent` - Reddit-style upvote/downvote (variants: default, compact, vertical, large)
- `StarRatingComponent` - 1-5 star rating with averages and counts
- `LikeButtonComponent` - Simple heart/like button
- `ReactionBarComponent` - Emoji reactions (Slack/GitHub style)

#### ActionCable Real-time Updates
- `VotesChannel` for live vote broadcasts
- JavaScript client for subscribing to vote updates
- Auto-subscribe functionality for widgets on page

#### Karma System
- `has_karma` DSL for reputation tracking
- Time decay with configurable half-life
- Weighted karma sources (upvotes vs downvotes)
- Karma levels with progress tracking (Newcomer -> Legend)
- Scoped karma calculation
- Karma caching support for performance
- `karma_level`, `karma_progress`, `recent_karma` methods

#### Styling
- Default CSS with dark mode support
- Size variants (compact, default, large, vertical)
- Fully customizable via CSS

### Changed
- **BREAKING**: Minimum Ruby version is now 3.2
- **BREAKING**: Minimum Rails version is now 7.2
- **BREAKING**: Votes use integer `value` instead of boolean
- **BREAKING**: New namespace `VoteFu::Vote` (was just `Vote`)
- **BREAKING**: Counter cache columns renamed for clarity

### Removed
- All legacy Rails 2/3/4 compatibility code
- `named_scope` usage (replaced with modern `scope`)
- `find(:all)` patterns
- External dependency on `statistics2` gem

## [0.0.11] - 2009-02-11

### Legacy
- Original VoteFu release for Rails 2.x
- Forked as ThumbsUp in 2010
- See https://github.com/peteonrails/vote_fu for historical code
