class Game < ApplicationRecord
  # ゲームの状態
  enum :status, { matching: 0, playing: 1, finished: 2 }, default: :matching

  # 勝者・敗者
  belongs_to :winner, class_name: "User", optional: true
  belongs_to :loser, class_name: "User", optional: true

  # 参加プレイヤー
  has_many :game_players, dependent: :destroy

  # 参加ユーザー一覧
  has_many :users, through: :game_players

  # 盤面のカードとターン履歴
  has_many :game_cards, dependent: :destroy
  has_many :turns, dependent: :destroy
end
