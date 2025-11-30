# frozen_string_literal: true

VoteFu::Engine.routes.draw do
  resources :votes, only: %i[create update destroy] do
    collection do
      post :toggle
    end
  end
end
