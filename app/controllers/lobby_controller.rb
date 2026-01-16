class LobbyController < ApplicationController
  def show
    @game_modes = [
      {
        id: "forbidden_library",
        title: "禁断の書庫",
        description: "ランク変動なし。新しいデッキを試すのに最適です。",
        image_path: "lobby/forbidden_library.jpg",
        action_text: "儀式を始める",
        badge: "CASUAL",
        url: matchmaking_path
      },
      {
        id: "mountains_of_madness",
        title: "未実装",
        description: "鋭意作成中！",
        image_path: "lobby/mountains_of_madness.jpg",
        action_text: "遠征に参加",
        badge: "RANKED"
      }
    ]
  end
end
