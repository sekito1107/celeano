class User < ApplicationRecord
  enum :role, { general: 0, admin: 1 }, default: :general
  # --- 参加記録 (詳細データ: HP/デッキなど) ---
  has_many :participations, class_name: "GamePlayer", dependent: :destroy

  # --- 対戦したゲーム (ゲーム本体: 勝敗/ターン数など) ---
  has_many :played_games, through: :participations, source: :game

  # 勝敗履歴
  has_many :won_games, class_name: "Game", foreign_key: "winner_id"
  has_many :lost_games, class_name: "Game", foreign_key: "loser_id"

  validates :name, presence: true
end
