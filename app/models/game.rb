class Game < ApplicationRecord
  include Loggable

  enum :status, { matching: 0, playing: 1, finished: 2 }, default: :matching

  before_validation :set_seed, on: :create

  FINISH_REASONS = {
    san_death: "SAN_DEATH",
    hp_death: "HP_DEATH",
    deck_death: "DECK_DEATH",
    surrender: "SURRENDER"
  }.freeze

  belongs_to :winner, class_name: "User", optional: true
  belongs_to :loser, class_name: "User", optional: true

  has_many :game_players, dependent: :destroy

  has_many :users, through: :game_players

  has_many :game_cards, dependent: :destroy
  has_many :turns, dependent: :destroy
  has_many :battle_logs, through: :turns

  def current_turn_number
    turns.maximum(:turn_number) || 1
  end

  def finish_game!(loser, reason)
    winner = game_players.where.not(id: loser.id).first

    transaction do
      update!(
        status: :finished,
        finish_reason: reason,
        winner_id: winner&.user_id,
        loser_id: loser.user_id,
        finished_at: Time.current
      )

      log_event!(:game_finish, {
        reason: reason,
        winner_player_id: winner&.user_id,
        loser_player_id: loser.user_id
      })
    end
  end

  def check_player_death!(player)
    return if finished?

    if player.san <= 0
      finish_game!(player, FINISH_REASONS[:san_death])
    elsif player.hp <= 0
      finish_game!(player, FINISH_REASONS[:hp_death])
    end
  end

  def finish_deck_death!(player)
    return if finished?

    player.log_event!(:deck_empty, {})
    finish_game!(player, FINISH_REASONS[:deck_death])
  end

  private

  def set_seed
    self.seed ||= rand(1..2_147_483_647)
  end
end
