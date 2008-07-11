class Vote < ActiveRecord::Base

  # NOTE: Votes belong to the "voteable" interface, and also to voters
  belongs_to :voteable, :polymorphic => true
  belongs_to :voter,    :polymorphic => true

  def self.find_votes_cast_by_voter(voter)
    find(:all,
      :conditions => ["voter_id = ? AND voter_type = ?", voter.id, voter.type.name],
      :order => "created_at DESC"
    )
  end
end