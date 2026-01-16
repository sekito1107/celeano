class User < ApplicationRecord
  # ===========================================
  # Rails 8 Authentication
  # ===========================================
  has_secure_password
  has_many :sessions, dependent: :destroy

  AVAILABLE_DECKS = %w[cthulhu hastur].freeze

  # メールアドレスの正規化（小文字化、前後空白除去）
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # ===========================================
  # Callbacks
  # ===========================================
  # コールバックは定義順に実行されるため、dependent: :destroy より前に定義する
  before_destroy :ensure_not_playing_active_game

  # ===========================================
  # Associations
  # ===========================================
  has_many :game_players, dependent: :destroy
  has_many :games, through: :game_players

  has_many :won_games, class_name: "Game", foreign_key: "winner_id", dependent: :nullify
  has_many :lost_games, class_name: "Game", foreign_key: "loser_id", dependent: :nullify

  has_many :game_cards, dependent: :destroy
  has_many :moves, dependent: :destroy

  # ===========================================
  # Validations
  # ===========================================
  validates :name, presence: true
  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :selected_deck, inclusion: { in: AVAILABLE_DECKS }

  private

  def ensure_not_playing_active_game
    if games.where(status: [ :matching, :playing ]).exists?
      errors.add(:base, "アクティブなゲームに参加中のユーザーは削除できません")
      throw :abort
    end
  end
end
