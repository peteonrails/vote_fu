require 'acts_as_voteable'
require 'acts_as_voter'
require 'has_karma'
require 'models/vote.rb'

ActiveRecord::Base.send(:include, Juixe::Acts::Voteable)
ActiveRecord::Base.send(:include, PeteOnRails::Acts::Voter)
ActiveRecord::Base.send(:include, PeteOnRails::VoteFu::Karma)

success_message = '** vote_fu: initialized properly.'

begin
  RAILS_DEFAULT_LOGGER.info success_message
rescue NameError
  Logger.new(STDOUT).info success_message
end

