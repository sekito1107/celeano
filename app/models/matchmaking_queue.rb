class MatchmakingQueue < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true, uniqueness: true
  validates :deck_type, presence: true
end
