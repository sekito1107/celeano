# frozen_string_literal: true

class Game::FieldComponent < ApplicationComponent
  def initialize(game_player:)
    @game_player = game_player
  end

  def deck_count
    # N+1対策: メモリ上の game_cards からカウント
    @game_player.game_cards.count { |gc| gc.location_deck? }
  end

  def graveyard_top_card
    # N+1対策: メモリ上の game_cards から検索 (updated_at, id でソートされている前提だが、game_cardsは順不同の可能性があるためソートが必要)
    # しかし、大量のカードがある場合 sort は重い。ここでは簡易的に id 最大を取得するか、
    # コントローラーでの incldes 時に order を指定するのがベストだが、
    # view_component 内での sort は許容範囲とする。
    @game_player.game_cards
                .select { |gc| gc.location_graveyard? }
                .max_by { |gc| [ gc.updated_at, gc.id ] }
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
