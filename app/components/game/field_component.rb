# frozen_string_literal: true

class Game::FieldComponent < ApplicationComponent
  def initialize(game_player:, viewer: nil)
    @game_player = game_player
    @viewer = viewer
  end

  def opponent?
    return false unless @viewer
    @game_player.user_id != @viewer.id
  end

  def deck_count
    # N+1対策: メモリ上の game_cards からカウント
    @game_player.game_cards.count { |gc| gc.location_deck? }
  end

  def graveyard_top_card
    sorted_cards_at(:graveyard).first
  end

  def banished_top_card
    sorted_cards_at(:banished).first
  end

  def graveyard_cards
    sorted_cards_at(:graveyard)
  end

  def banished_cards
    sorted_cards_at(:banished)
  end

  private

  def sorted_cards_at(location)
    # N+1対策: メモリ上の game_cards から検索
    cards = @game_player.game_cards.select { |gc| gc.send("location_#{location}?") }

    # updated_at, id の降順でソート (最新が先頭)
    cards.sort_by { |gc| [ gc.updated_at, gc.id ] }.reverse
  end

  def slot_card(position)
    # N+1対策: メモリ上の game_cards から検索
    @game_player.game_cards.find { |gc| (gc.location_board? || gc.location_resolving?) && gc.position == position.to_s }
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
