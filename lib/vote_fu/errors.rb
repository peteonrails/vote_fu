# frozen_string_literal: true

module VoteFu
  # Base error class for all VoteFu errors
  class Error < StandardError; end

  # Raised when a voter attempts to vote again without recast enabled
  class AlreadyVotedError < Error
    def initialize(msg = "Already voted on this item")
      super
    end
  end

  # Raised when a model attempts to vote on itself
  class SelfVoteError < Error
    def initialize(msg = "Cannot vote on yourself")
      super
    end
  end

  # Raised when an invalid vote value is provided
  class InvalidVoteValueError < Error
    def initialize(msg = "Vote value must be an integer")
      super
    end
  end

  # Raised when voteable is not found
  class VoteableNotFoundError < Error
    def initialize(msg = "Voteable not found")
      super
    end
  end
end
