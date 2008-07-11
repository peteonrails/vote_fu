# ActsAsVoter
module PeteOnRails
  module Acts #:nodoc:
    module Voter #:nodoc:

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_voter
          has_many :votes, :as => :voter, :dependent => :nullify  # If a voting entity is deleted, keep the votes. 
            include PeteOnRails::Acts::Voter::InstanceMethods
          extend  PeteOnRails::Acts::Voter::SingletonMethods
        end
      end
      
      # This module contains class methods
      module SingletonMethods
        def find_votes_cast_by(voter)
          Vote.find(:all,
            :conditions => ["voter_id = ? and voter_type = ?", voter.id, voter.type.name],
            :order => "created_at DESC"
          )
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        
        # Usage user.vote_count(true)  # All +1 votes
        #       user.vote_count(false) # All -1 votes
        #       user.vote_count()      # All votes
        
        def vote_count(for_or_against = "all")
          where = (for_or_against = "all") ? 
            ["voter_id = ? AND voter_type = ?", id, self.type.name ] : 
            ["voter_id = ? AND voter_type = ? AND vote = ?", id, self.type.name, for_or_against ]
                        
          Vote.count(:all, :conditions => where)

        end
                
        def voted_for?(voteable)
          0 < Vote.count(:all, :conditions => [
                  "voter_id = ? AND voter_type = ? AND vote = TRUE AND voteable_id = ? AND voteable_type = ?",
                  self.id, self.type.name, voteable.id, voteable.type.name
                  ])
        end
      end
    end
  end
end
