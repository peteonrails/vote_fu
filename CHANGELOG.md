# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0.alpha1] - 2024-11-29

### Added
- Complete rewrite for Rails 8+
- Integer vote values (supports up/down, star ratings, weighted votes)
- Scoped voting (multiple vote contexts per voteable)
- Wilson Score confidence interval algorithm
- Reddit Hot ranking algorithm
- Hacker News ranking algorithm
- Karma calculation system
- Counter cache support
- Modern `ActiveSupport::Concern` based architecture
- RSpec test suite
- Install generator

### Changed
- Minimum Ruby version: 3.2
- Minimum Rails version: 7.2
- New gem structure as Rails Engine

### Removed
- All legacy Rails 2/3 code
- Boolean vote values (replaced with integers)
- Named scopes syntax (use modern `scope`)

## [0.0.11] - 2009-02-11

### Legacy
- Original VoteFu release for Rails 2.x
- See https://github.com/peteonrails/vote_fu for historical code
