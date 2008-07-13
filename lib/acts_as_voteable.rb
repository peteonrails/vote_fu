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
        def find_votes_cast_by_user(user)
          voteable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          Vote.find(:all,
            :conditions => ["user_id = ? and voteable_type = ?", user.id, voteable],
            :order => "created_at DESC"
          )
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        def votes_for
          Vote.count(:all, :conditions => [
            "voteable_id = ? AND voteable_type = ? AND vote = ?",
            id, self.type.name, true
          ])
        end
        
        def votes_against
          Vote.count(:all, :conditions => [
            "voteable_id = ? AND voteable_type = ? AND vote = ?",
            id, self.type.name, false
          ])
        end
        
        # Same as voteable.votes.size
        def votes_count
          self.votes.size
        end
        
        def users_who_voted
          users = []
          self.votes.each { |v|
            users << v.user
          }
          users
        end
        
        def voted_by_user?(user)
          rtn = false
          if user
            self.votes.each { |v|
              rtn = true if user.id == v.user_id
            }
          end
          rtn
        end
      end
    end
  end
end
