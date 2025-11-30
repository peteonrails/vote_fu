# frozen_string_literal: true

# Only load engine when Rails is present
if defined?(Rails::Engine)
  require "turbo-rails"

  module VoteFu
    class Engine < ::Rails::Engine
      isolate_namespace VoteFu

      # Load concerns when ActiveRecord is ready
      initializer "vote_fu.active_record" do
        ActiveSupport.on_load(:active_record) do
          require "vote_fu/concerns/voteable"
          require "vote_fu/concerns/voter"
          require "vote_fu/concerns/karmatic"

          include VoteFu::Concerns::Voteable
          include VoteFu::Concerns::Voter
          include VoteFu::Concerns::Karmatic
        end
      end

      # Include helpers in ActionView
      initializer "vote_fu.helpers" do
        ActiveSupport.on_load(:action_view) do
          include VoteFu::VotesHelper
        end
      end

      # Set up importmap for Stimulus controllers
      initializer "vote_fu.importmap", before: "importmap" do |app|
        if app.config.respond_to?(:importmap)
          app.config.importmap.paths << Engine.root.join("config/importmap.rb")
          app.config.importmap.cache_sweepers << Engine.root.join("app/javascript")
        end
      end

      # Append engine assets to asset pipeline
      initializer "vote_fu.assets" do |app|
        if app.config.respond_to?(:assets)
          app.config.assets.paths << Engine.root.join("app/assets/stylesheets")
        end
      end

      # Configure generators
      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot
        g.factory_bot dir: "spec/factories"
      end
    end
  end
end
