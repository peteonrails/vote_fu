require 'acts_as_voteable'

ActiveRecord::Base.send(:include, Juixe::Acts::Voteable)
ActiveRecord::Base.send(:include, PeteOnRails::Acts::Voter)
RAILS_DEFAULT_LOGGER.info "** vote_fu: initialized properly."