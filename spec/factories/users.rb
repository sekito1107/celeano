FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Player#{n}" }
    sequence(:email_address) { |n| "player#{n}@example.com" }
    password { "password123" }
  end
end
