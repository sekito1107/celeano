class GameCard < ApplicationRecord
  include Loggable

  belongs_to :game
  belongs_to :user
  belongs_to :card
  belongs_to :game_player
  has_many :modifiers, class_name: "GameCardModifier", dependent: :destroy
  has_many :moves, dependent: :destroy

  enum :location, { deck: 0, hand: 1, board: 2, graveyard: 3, resolving: 4 }, prefix: true
  enum :position, { left: 0, center: 1, right: 2 }, prefix: true

  validates :user_id, :game_player_id, presence: true
  validate :user_matches_game_player

  before_validation :initialize_stats, on: :create

  delegate :haste?, :guardian?, to: :card

  def has_summon_sickness?
    return false if haste?

    current_turn = game.current_turn_number
    summoned_turn == current_turn
  end

  def stunned?
    modifiers.exists?(effect_type: :stun)
  end

  def can_attack?
    location_board? && !has_summon_sickness? && !stunned?
  end

  def take_damage!(amount)
    new_hp = [ current_hp - amount, 0 ].max
    update!(current_hp: new_hp)
  end

  def apply_poison_damage!
    total_damage = modifiers.where(effect_type: :poison).sum("COALESCE(value, 1)")
    take_damage!(total_damage) if total_damage > 0
    total_damage
  end

  def attack_buff_value
    modifiers.where(effect_type: :attack_buff).sum("COALESCE(value, 0)")
  end

  def total_attack
    base = current_attack.to_s
    buff = attack_buff_value
    return base if buff == 0

    if base.match?(/\A\d+\z/)
      (base.to_i + buff).to_s
    else
      buff >= 0 ? "#{base}+#{buff}" : "#{base}#{buff}"
    end
  end

  def tick_modifiers!
    transaction do
      active_modifiers = modifiers.where.not(duration: nil)

      # 期限切れになるモディファイアを特定
      to_expire_ids = active_modifiers.where(duration: ..1).pluck(:id, :effect_type)
      expired_types = to_expire_ids.map(&:last)

      # 期限切れを削除
      modifiers.where(id: to_expire_ids.map(&:first)).destroy_all if to_expire_ids.any?

      # 残りのモディファイアのdurationを減らす
      active_modifiers.where("duration > 1").update_all("duration = duration - 1")

      expired_types
    end
  end

  def dead?
    current_hp <= 0
  end

  def move_to_hand!(stack_index)
    update!(
      location: :hand,
      position_in_stack: stack_index,
      position: nil
    )
  end

  def discard!
    update!(
      location: :graveyard,
      position_in_stack: nil,
      position: nil,
      current_hp: 0
    )
  end

  # Planningフェーズでカードを予約状態にする
  # 解決フェーズで実際にボードに配置される
  def reserve_to!(board_position)
    update!(
      location: :resolving,
      position: board_position,
      position_in_stack: nil
    )
  end

  def summon_to!(board_position)
    update!(
      location: :board,
      position: board_position,
      position_in_stack: nil,
      summoned_turn: game.current_turn_number
    )
  end

  def trigger(timing, target = nil)
    effect_definition = CardEffects::Registry.find(card.key_code)
    return unless effect_definition

    context = CardEffects::Context.new(
      source_card: self,
      target: target,
      timing: timing
    )

    actual_timing = resolve_actual_timing(timing, context, effect_definition)
    return unless actual_timing

    effect_definition.execute(actual_timing, context)
  end

  def has_effect?(timing)
    effect_definition = CardEffects::Registry.find(card.key_code)
    return false unless effect_definition

    insane_timing = "#{timing}_insane".to_sym
    effect_definition.has_timing?(timing) || effect_definition.has_timing?(insane_timing)
  end

  private

  def user_matches_game_player
    return if user_id.nil? || game_player_id.nil?

    if user_id != game_player.user_id
        errors.add(:user_id, "must match the user of the associated game_player")
    end
  end

  def log_effect_trigger(timing, target, is_insane:)
    log_event!(:effect_trigger, {
      card_name: card.name,
      key_code: card.key_code,
      timing: timing,
      is_insane: is_insane,
      target_id: target&.id
    })
  end

  # 狂気状態なら狂気版タイミングを優先して返す
  def resolve_actual_timing(timing, context, effect_definition)
    insane_timing = "#{timing}_insane".to_sym

    if context.insane? && effect_definition.has_timing?(insane_timing)
      log_effect_trigger(insane_timing, context.target, is_insane: true)
      insane_timing
    elsif effect_definition.has_timing?(timing)
      log_effect_trigger(timing, context.target, is_insane: false)
      timing
    end
  end

  def initialize_stats
    self.current_hp ||= card.hp
    self.current_attack ||= card.attack
  end
end
