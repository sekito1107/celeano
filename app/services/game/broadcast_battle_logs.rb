class Game::BroadcastBattleLogs
  def self.call(game:, logs:)
    # 盤面の更新通知（Turbo Stream用）
    GameChannel.broadcast_to(game, {
      type: "board_update"
    })

    # バトルログのデータ配信（アニメーション用）
    GameChannel.broadcast_to(game, {
      type: "battle_logs",
      logs: (logs || []).map { |log|
        {
          event_type: log.event_type,
          details: log.details,
          timestamp: log.created_at.to_i
        }
      }
    })
  end
end
