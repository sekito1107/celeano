# frozen_string_literal: true

module Lobby
  class DeckSelectorComponent < ApplicationComponent
    def initialize(user:)
      @user = user
    end

    def selected_deck
      @user.selected_deck
    end

    def available_decks
      User::AVAILABLE_DECKS
    end
  end
end
