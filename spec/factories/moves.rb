FactoryBot.define do
  factory :move do
    association :turn
    association :game_card
    user { game_card.user }
    action_type { :play }
    position { 0 }

    trait :spell do
      action_type { :spell }
      position { nil }
    end

    trait :attack do
      action_type { :attack }
      position { nil }
    end
  end
end
