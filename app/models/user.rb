class User < ApplicationRecord
  # コールバックは定義順に実行されるため、dependent: :destroy より前に定義する
  before_destroy :ensure_not_playing_active_game

  has_many :game_players, dependent: :destroy
  has_many :games, through: :game_players

  has_many :won_games, class_name: "Game", foreign_key: "winner_id", dependent: :nullify
  has_many :lost_games, class_name: "Game", foreign_key: "loser_id", dependent: :nullify

  has_many :game_cards, dependent: :destroy

  has_many :moves, dependent: :destroy

  validates :name, presence: true

  private

  def ensure_not_playing_active_game
    if games.where(status: [ :matching, :playing ]).exists?
      errors.add(:base, "アクティブなゲームに参加中のユーザーは削除できません")
      throw :abort
    end
  end
end
