FactoryBot.define do
  factory :game_card do
    association :game
    association :user
    association :card

    game_player do
      GamePlayer.find_or_create_by!(game: game, user: user) do |gp|
        # 必須属性のデフォルト値を設定が必要な場合
        gp.hp = 20
        gp.san = 20
      end
    end

    location { :deck }
    position_in_stack { 0 }

    after(:build) do |game_card|
      if game_card.game_player.present? && game_card.user != game_card.game_player.user
        game_card.user = game_card.game_player.user
      end
    end
  end
end
