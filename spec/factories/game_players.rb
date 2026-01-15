FactoryBot.define do
  factory :game_player do
    association :game
    association :user

    role { :host }
    hp { 20 }
    san { 20 }

    trait :guest do
      role { :guest }
    end

    trait :with_deck do
      transient do
        deck_count { 2 }
      end

      after(:create) do |game_player, evaluator|
        card = Card.where(name: 'TEST_UNIT').first || create(:card, :unit, name: 'TEST_UNIT')
        evaluator.deck_count.times do |i|
          create(:game_card,
            game: game_player.game,
            user: game_player.user,
            game_player: game_player,
            card: card,
            location: :deck,
            position_in_stack: i
          )
        end
      end
    end
  end
end
