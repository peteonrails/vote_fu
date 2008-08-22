# Has Karma

module PeteOnRails
  module VoteFu #:nodoc:
    module Karma #:nodoc:

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def has_karma(voteable_type)
          self.class_eval <<-RUBY
            def karma_voteable
              #{voteable_type.to_s.classify}
            end
          RUBY
          
          include PeteOnRails::VoteFu::Karma::InstanceMethods
          extend  PeteOnRails::VoteFu::Karma::SingletonMethods
        end
      end
      
      # This module contains class methods
      module SingletonMethods
        
        ## Not yet implemented. Don't use it!
        # Find the most popular users
        def find_most_karmic
          find(:all)
        end
                      
      end
      
      # This module contains instance methods
      module InstanceMethods
        def karma(options = {})
          # count the total number of votes on all of the voteable objects that are related to this object
          self.karma_voteable.sum(:vote, options_for_karma(options))          
        end
        
        def options_for_karma (options = {})
            conditions = ["u.id = ?" , self[:id] ]
            joins = ["inner join votes v on #{karma_voteable.table_name}.id = v.voteable_id", "inner join #{self.class.table_name} u on u.id = #{karma_voteable.name.tableize}.#{self.class.name.foreign_key}"]            
            { :joins => joins.join(" "), :conditions => conditions }.update(options)          
        end
        
      end
      
    end
  end
end
