FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Player#{n}" }
  end
end
