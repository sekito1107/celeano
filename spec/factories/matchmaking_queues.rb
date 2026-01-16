FactoryBot.define do
  factory :matchmaking_queue do
    association :user
    deck_type { "cthulhu" }
  end
end
