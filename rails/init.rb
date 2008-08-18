require 'acts_as_voteable'
require 'acts_as_voter'
require 'has_karma'
require 'models/vote.rb'

%w{ models controllers helpers }.each do |dir|
  path = File.join(File.dirname(__FILE__) , 'lib', dir)
  $LOAD_PATH << path
  Dependencies.load_paths << path
  Dependencies.load_once_paths.delete(path)
end

ActiveRecord::Base.send(:include, Juixe::Acts::Voteable)
ActiveRecord::Base.send(:include, PeteOnRails::Acts::Voter)
ActiveRecord::Base.send(:include, PeteOnRails::VoteFu::Karma)
RAILS_DEFAULT_LOGGER.info "** vote_fu: initialized properly."