# ActsAsVoteable
module Juixe
  module Acts #:nodoc:
    module Voteable #:nodoc:

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_voteable
          has_many :votes, :as => :voteable, :dependent => :nullify
          include Juixe::Acts::Voteable::InstanceMethods
          extend  Juixe::Acts::Voteable::SingletonMethods
        end
      end
      
      # This module contains class methods
      module SingletonMethods
      end
      
      # This module contains instance methods
      module InstanceMethods
        def votes_for
          Vote.count(:all, :conditions => [
            "voteable_id = ? AND voteable_type = ? AND vote = ?",
            id, self.class.name, true
          ])
        end
        
        def votes_against
          Vote.count(:all, :conditions => [
            "voteable_id = ? AND voteable_type = ? AND vote = ?",
            id, self.class.name, false
          ])
        end
        
        # Same as voteable.votes.size
        def votes_count
          self.votes.size
        end
        
        def voters_who_voted
          voters = []
          self.votes.each { |v|
            voters << v.voter
          }
          users
        end
        
        def voted_by?(voter)
          rtn = false
          if voter
            self.votes.each { |v|
              rtn = true if (voter.id == v.voter_id && voter.class.name == v.voter_type)
            }
          end
          rtn
        end
        
        
      end
    end
  end
end
