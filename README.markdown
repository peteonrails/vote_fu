vote_fu
=======

Allows an arbitrary number of entites (including Users) to vote on models. Adapted from act\_as\_voteable. Differences from acts\_as\_voteable include: 

1. You can specify the model name that initiates votes. 
2. You can, with a little tuning, have more than one entity type vote on more than one model type. 
3. Adds "acts\_as\_voter" behavior to the initiator of votes.
4. Introduces some newer Rails features like named\_scope and :polymorphic keywords


Install
_______

Run the following command:

    ./script/plugin install git://github.com/peteonrails/vote_fu.git 
	
Create a new rails migration using the generator:

    ./script/generate voteable
	
 
Usage
_____ 

### Make your ActiveRecord model act as voteable.


    class Model < ActiveRecord::Base
 	  acts_as_voteable
    end


### Make your ActiveRecord model(s) that vote act as voter.

    class User < ActiveRecord::Base
 	  acts_as_voter
    end

    class Robot < ActiveRecord::Base
   	  acts_as_voter
    end

### To cast a vote for a Model you can do the following:

    vote = Vote.new(:vote => true)
    m    = Model.find(params[:id])
    m.votes    << vote
    user.votes << vote

There will be new functionality coming soon to make casting a vote simpler. 

### Querying votes

ActiveRecord models that act as voteable can be queried for the positive votes, negative votes, and a total vote count by using the votes\_for, votes\_against, and votes\_count methods respectively. Here is an example:

    positiveVoteCount = m.votes_for
    negativeVoteCount = m.votes_against
    totalVoteCount    = m.votes_count

And because the Vote Fu plugin will add the has_many votes relationship to your model you can always get all the votes by using the votes property:

    allVotes = m.votes

#### Named Scopes

The Vote model has several named scopes you can use to find vote details: 

    @pete_votes = Vote.for_voter(pete)
    @post_votes = Vote.for_voteable(post)
    @recent_votes = Vote.recent(1.day.ago)
    @descending_votes = Vote.descending

You can chain these together to make interesting queries: 

    # Show all of Pete's recent votes for a certain Post, in descending order (newest first)
    @pete_recent_votes_on_post = Vote.for_voter(pete).for_voteable(post).recent(7.days.ago).descending

Credits
_______
[Juixe  - The original ActsAsVoteable plugin inspired this code.][1]

[Xelipe - This plugin is heavily influenced by Acts As Commentable.][2]

[1]: http://www.juixe.com/techknow/index.php/2006/06/24/acts-as-voteable-rails-plugin/
[2]: http://github.com/jackdempsey/acts_as_commentable/tree/master

More
____

[Documentation from the original acts\_as\_voteable plugin][3]

[3]: http://www.juixe.com/techknow/index.php/2006/06/24/acts-as-voteable-rails-plugin/