# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module VoteFu
  module Generators
    class MigrationGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Creates the VoteFu votes table migration"

      def create_migration_file
        migration_template(
          "create_vote_fu_votes.rb.erb",
          "db/migrate/create_vote_fu_votes.rb"
        )
      end

      private

      def migration_version
        "[#{ActiveRecord::Migration.current_version}]"
      end
    end
  end
end
