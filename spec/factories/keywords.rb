FactoryBot.define do
  factory :keyword do
    initialize_with { Keyword.find_or_initialize_by(name: name) }

    sequence(:name) { |n| "keyword_#{n}" }
    description { "キーワード説明" }

    trait :haste do
      name { "haste" }
      description { "召喚酔いなしで攻撃可能" }
    end

    trait :guardian do
      name { "guardian" }
      description { "他のユニットへの攻撃を引きつける" }
    end
  end
end
