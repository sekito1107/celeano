FactoryBot.define do
  factory :card do
    sequence(:name) { |n| "Card #{n}" }
    sequence(:key_code) { |n| "card_code_#{n}" }
    cost { "1d6" }
    hp { 1 }
    attack { "1" }

    trait :unit do
      card_type { :unit }
    end

    trait :spell do
      card_type { :spell }
    end

    trait :nil_threshold do
      threshold_san { nil }
    end

    trait :with_haste do
      after(:create) do |card|
        haste = Keyword.find_or_create_by!(name: "haste") do |k|
          k.description = "召喚酔いなしで攻撃可能"
        end
        card.keywords << haste unless card.keywords.include?(haste)
      end
    end

    trait :with_guardian do
      after(:create) do |card|
        guardian = Keyword.find_or_create_by!(name: "guardian") do |k|
          k.description = "他のユニットへの攻撃を引きつける"
        end
        card.keywords << guardian unless card.keywords.include?(guardian)
      end
    end
  end
end
