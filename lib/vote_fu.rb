# frozen_string_literal: true

require "vote_fu/version"
require "vote_fu/configuration"
require "vote_fu/errors"
require "vote_fu/engine"

module VoteFu
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
