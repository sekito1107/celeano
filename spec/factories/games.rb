FactoryBot.define do
  factory :game do
    status { :playing }
    seed { 12345 }
  end
end
