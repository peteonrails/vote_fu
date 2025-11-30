# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module VoteFu
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Install VoteFu: creates initializer and migration"

      def create_initializer
        template "initializer.rb", "config/initializers/vote_fu.rb"
      end

      def create_migration
        migration_template(
          "migration.rb.erb",
          "db/migrate/create_vote_fu_votes.rb"
        )
      end

      def show_post_install_message
        say ""
        say "VoteFu installed successfully!", :green
        say ""
        say "Next steps:"
        say "  1. Run migrations: rails db:migrate"
        say "  2. Add to your models:"
        say ""
        say "     class Post < ApplicationRecord"
        say "       acts_as_voteable"
        say "     end"
        say ""
        say "     class User < ApplicationRecord"
        say "       acts_as_voter"
        say "     end"
        say ""
        say "  3. Start voting:"
        say "     user.upvote(post)"
        say "     user.downvote(post)"
        say "     post.plusminus"
        say ""
      end

      private

      def migration_version
        "[#{ActiveRecord::Migration.current_version}]"
      end
    end
  end
end
