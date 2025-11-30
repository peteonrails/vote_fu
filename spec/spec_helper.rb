# frozen_string_literal: true

require "bundler/setup"
require "active_record"

# Load VoteFu without the engine (for testing without Rails)
require "vote_fu/version"
require "vote_fu/configuration"
require "vote_fu/errors"

module VoteFu
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

# Load concerns directly
require "vote_fu/concerns/voteable"
require "vote_fu/concerns/voter"
require "vote_fu/concerns/karmatic"

# Load algorithms
require "vote_fu/algorithms/wilson_score"
require "vote_fu/algorithms/reddit_hot"
require "vote_fu/algorithms/hacker_news"

# Include concerns in ActiveRecord
ActiveRecord::Base.include VoteFu::Concerns::Voteable
ActiveRecord::Base.include VoteFu::Concerns::Voter
ActiveRecord::Base.include VoteFu::Concerns::Karmatic

# Set up in-memory SQLite database
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

# Suppress ActiveRecord logging in tests
ActiveRecord::Base.logger = Logger.new(nil)

# Load support files
Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  config.before(:suite) do
    CreateTestTables.up
  end

  config.before(:each) do
    VoteFu.reset_configuration!
  end

  config.after(:each) do
    # Clean up votes between tests
    VoteFu::Vote.delete_all
    Post.delete_all
    User.delete_all
  end
end
