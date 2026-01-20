class Game::BroadcastBattleLogs
  def self.call(game:, logs:)
    # 盤面更新とバトルログをまとめて配信
    GameChannel.broadcast_to(game, {
      type: "game_update",
      board_update: true,
      battle_logs: (logs || []).map { |log|
        {
          event_type: log.event_type,
          details: log.details,
          timestamp: log.created_at.to_i
        }
      }
    })
  end
end
