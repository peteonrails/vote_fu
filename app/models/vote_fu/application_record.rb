# frozen_string_literal: true

module VoteFu
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
