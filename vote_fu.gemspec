Gem::Specification.new do |s|
  s.name = "vote_fu"
  s.version = "0.0.3"
  s.date = "2008-07-10"
  s.summary = "Voting for ActiveRecord with multiple vote sources and advanced features."
  s.email = "pete@peteonrails.com"
  s.homepage = "http://blog.peteonrails.com/vote-fu"
  s.description = "VoteFu provides the ability to have multiple voting entities on an arbitrary number of models in ActiveRecord."
  s.has_rdoc = false
  s.authors = ["Peter Jackson", "Cosmin Radoi"]
  s.files = [ "CHANGELOG",
              "MIT-LICENSE",
              "README",
              "generators/voteable",
              "generators/voteable/voteable_generator.rb",
              "generators/voteable/templates",
              "generators/voteable/templates/vote.rb",
              "generators/voteable/templates/migration.rb",
              "init.rb",
              "lib/acts-as-voteable.rb",
              "lib/acts_as_voter.rb",
              "rails/init.rb",
              "test/voteable_test.rb",
              "examples/votes_controller.rb",
              "examples/users_controller.rb",
              "examples/voteables_controller.rb",
              "examples/voteable.rb",
              "examples/voteable.html.erb"
              "examples/votes/_voteable_vote.html.erb"
              "examples/votes/create.rjs"
              "examples/routes.rb"
               ]
end