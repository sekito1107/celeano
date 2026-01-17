# frozen_string_literal: true

class Game::FieldComponent < ApplicationComponent
  def initialize(game_player:)
    @game_player = game_player
  end

  def deck_count
    @game_player.deck.count
  end

  def graveyard_top_card
    @game_player.graveyard.last
  end

  def slot_card(position)
    # N+1対策: メモリ上の game_cards から検索
    @game_player.game_cards.find { |gc| gc.location_board? && gc.position == position.to_s }
  end

  def left_slot_card
    slot_card(:left)
  end

  def center_slot_card
    slot_card(:center)
  end

  def right_slot_card
    slot_card(:right)
  end
end
