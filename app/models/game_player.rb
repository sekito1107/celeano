class GamePlayer < ApplicationRecord
  include Loggable

  belongs_to :game
  belongs_to :user
  has_many :game_cards, dependent: :destroy

  enum :role, { host: 0, guest: 1 }

  validates :hp, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :san, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def deck
    game_cards.where(location: :deck).order(:position_in_stack)
  end

  def hand
    game_cards.where(location: :hand).order(:position_in_stack)
  end

  def graveyard
    game_cards.where(location: :graveyard).order(:updated_at, :id)
  end

  def pay_cost!(amount)
    new_san = [ san - amount, 0 ].max
    update!(san: new_san)
    log_event!(:pay_cost, { amount: amount, current_san: new_san })
  end

  def insane?
    san <= 0
  end

  def take_damage!(amount)
    new_hp = [ hp - amount, 0 ].max
    update!(hp: new_hp)
    log_event!(:take_damage, { amount: amount, current_hp: new_hp })
  end

  def draw_card!
    game_card = deck.first
    return nil unless game_card

    current_max_position = hand.maximum(:position_in_stack)
    next_index = (current_max_position || -1) + 1

    game_card.move_to_hand!(next_index)
    log_event!(:draw, { card_id: game_card.id, card_name: game_card.card.name, key_code: game_card.card.key_code })

    game_card
  end

  def discard_card!(game_card, reason: :manual)
    unless game_card.game_player_id == id && game_card.location_hand?
      raise ArgumentError, "Card is not in player's hand"
    end

    ActiveRecord::Base.transaction do
      game_card.discard!

      log_event!(:discard, {
        card_id: game_card.id,
        card_name: game_card.card.name,
        reason: reason
      })
    end
  end

  def surrender!
    game.with_lock do
      return if game.finished?

      game.finish_game!(self, Game::FINISH_REASONS[:surrender])
    end
  end
end
