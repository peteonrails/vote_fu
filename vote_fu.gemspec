# frozen_string_literal: true

require_relative "lib/vote_fu/version"

Gem::Specification.new do |spec|
  spec.name = "vote_fu"
  spec.version = VoteFu::VERSION
  spec.authors = ["Peter Jackson"]
  spec.email = ["pete@peteonrails.com"]

  spec.summary = "Modern voting for Rails 8+ with Turbo, Stimulus, and ActionCable"
  spec.description = <<~DESC
    VoteFu provides flexible voting capabilities for Rails applications.
    Features include up/down voting, star ratings, scoped voting contexts,
    Wilson Score ranking, Reddit Hot algorithm, counter caches, and
    first-class Hotwire support with Turbo Streams and Stimulus controllers.
  DESC
  spec.homepage = "https://votefu.dev"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/peteonrails/vote_fu"
  spec.metadata["changelog_uri"] = "https://github.com/peteonrails/vote_fu/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["{app,config,lib}/**/*", "MIT-LICENSE", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "rails", ">= 7.2", "< 9.0"
  spec.add_dependency "turbo-rails", ">= 2.0"
  spec.add_dependency "view_component", ">= 3.0"

  spec.add_development_dependency "rspec-rails", "~> 7.0"
  spec.add_development_dependency "factory_bot_rails", "~> 6.4"
  spec.add_development_dependency "sqlite3", "~> 2.0"
  spec.add_development_dependency "rubocop", "~> 1.68"
  spec.add_development_dependency "rubocop-rails", "~> 2.27"
  spec.add_development_dependency "rubocop-rspec", "~> 3.2"
end
