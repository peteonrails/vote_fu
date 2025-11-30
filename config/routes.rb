# frozen_string_literal: true

VoteFu::Engine.routes.draw do
  resources :votes, only: %i[create destroy]
end
