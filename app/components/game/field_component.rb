# frozen_string_literal: true

class Game::FieldComponent < ApplicationComponent
  def initialize(game_player:, viewer: nil, current_turn: nil)
    @game_player = game_player
    @viewer = viewer
    @current_turn = current_turn
  end

  def opponent?
    return false unless @viewer
    @game_player.user_id != @viewer.id
  end

  def viewer_is_player?
    @viewer && @viewer.id == @game_player.user_id
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

  def render_slot_card(card)
    return nil unless card

    card_html = render Game::CardComponent.new(card_entity: card, variant: :field)

    if !opponent? && card.location_resolving?
      tag.div(**cancellation_attributes(card)) { card_html }
    else
      card_html
    end
  end

  def slot_card(position)
    find_board_card(position) || find_scheduled_card(position)
  end

  def find_board_card(position)
    # N+1対策: メモリ上の game_cards から検索
    @game_player.game_cards.find { |gc| gc.location_board? && gc.position == position.to_s }
  end

  def find_scheduled_card(position)
    # 相手の場合は召喚予定を見せない
    return nil if opponent?

    # 召喚予定カードを検索 (Move経由)
    move = current_turn&.moves&.find do |m|
      m.user_id == @game_player.user_id &&
      m.action_type_play? &&
      m.position == position.to_s
    end

    move&.game_card
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

  def current_turn
    @current_turn ||= @game_player.game.turns.find_by(turn_number: @game_player.game.current_turn_number)
  end

  def unit_limit
    current_turn&.unit_summon_limit || Turn::DEFAULT_SUMMON_LIMIT
  end

  def units_summoned
    current_turn&.units_summoned_count(@game_player.user) || 0
  end

  def pending_cost_text
    return nil unless viewer_is_player?

    # current_turnはprivateなのでここで定義済みのメソッドを使う
    return nil unless current_turn

    min_total, max_total = current_turn.pending_cost_range_for(@game_player.user)

    return nil if max_total == 0

    if min_total == max_total
      "#{min_total}"
    else
      "#{min_total}~#{max_total}"
    end
  end

  def cancellation_attributes(card)
    return {} unless card.location_resolving?

    {
      draggable: "true",
      data: {
        card_id: card.id,
        card_type: "cancel",
        action: "dblclick->game--board#cancelCard dragstart->game--board#dragstart"
      },
      class: "draggable-source"
    }
  end
end
