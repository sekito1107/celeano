# 毎ターンの状態異常効果を処理する
# ロジックはGameCardモデルに委譲
class ProcessStatusEffects
  include Interactor

  def call
    game = context.game
    return if game.finished?

    ActiveRecord::Base.transaction do
      board_units = game.game_cards.where(location: :board).includes(:card)
      board_units.each do |game_card|
        process_poison(game_card)
        process_modifier_ticks(game_card)
      end
    end
  end

  private

  def process_poison(game_card)
    damage = game_card.apply_poison_damage!
    return if damage.zero?

    game_card.log_event!(:poison_damage, {
      card_id: game_card.id,
      card_name: game_card.card.name,
      damage: damage,
      current_hp: game_card.current_hp
    })
  end

  def process_modifier_ticks(game_card)
    expired = game_card.tick_modifiers!
    expired.each do |modifier_type|
      game_card.log_event!(:modifier_expired, {
        card_id: game_card.id,
        card_name: game_card.card.name,
        modifier_type: modifier_type
      })
    end
  end
end
