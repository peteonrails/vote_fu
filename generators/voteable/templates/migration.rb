class ActsAsVoteableMigration < ActiveRecord::Migration
  def self.up
    create_table :votes, :force => true do |t|
      t.boolean  :vote,                        :default => false
      t.string   :voteable_type, :limit => 15, :default => "", :null => false
      t.integer  :voteable_id,                 :default => 0,  :null => false
      t.integer  :voter_id,                    :default => 0,  :null => false
      t.string   :voter_type,    :limit => 15, :default => "", :null => false
      t.timestamps      
    end

    add_index :votes, ["voter_id", "voter_type"], :name => "fk_voters"
    add_index :votes, ["voteable_id", "voteable_type"], :name => "fk_voteables"
  end

  def self.down
    drop_table :votes
  end

end
