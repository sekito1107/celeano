FactoryBot.define do
  factory :game_card_modifier do
    game_card
    effect_type { :poison }
    value { 1 }
    duration { 1 }
    source_name { "テストカード" }
    modification_type { :temporary }

    trait :stun do
      effect_type { :stun }
      duration { 1 }
    end

    trait :attack_buff do
      effect_type { :attack_buff }
      value { 2 }
    end

    trait :hp_buff do
      effect_type { :hp_buff }
      value { 3 }
    end

    trait :permanent_attack_buff do
      effect_type { :attack_buff }
      value { 2 }
      modification_type { :permanent }
      duration { nil }
    end

    trait :permanent_hp_buff do
      effect_type { :hp_buff }
      value { 3 }
      modification_type { :permanent }
      duration { nil }
    end
  end
end
