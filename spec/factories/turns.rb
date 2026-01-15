FactoryBot.define do
  factory :turn do
    association :game
    turn_number { 1 }
    status { :planning }
  end
end
