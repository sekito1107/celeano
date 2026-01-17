class JoinMatchmaking
  include Interactor

  def call
    user = context.user
    deck_type = context.deck_type

    active_game = user.games.find_by(status: [ :matching, :playing ])
    if active_game
      user.matchmaking_queue&.destroy!
      context.game = active_game
      return
    end

    ActiveRecord::Base.transaction do
      # 既に参加済みなら削除（リセット）
      user.matchmaking_queue&.destroy!

      # 対戦相手を探す (排他ロック)
      opponent_queue = find_opponent(user)

      if opponent_queue
        handle_match_found(user, deck_type, opponent_queue)
      else
        handle_no_match(user, deck_type)
      end
    end

    if context.broadcast_target && context.game
      MatchmakingChannel.broadcast_to(
        context.broadcast_target,
        action: "matched",
        game_id: context.game.id,
        opponent_name: user.name,
        opponent_image: ActionController::Base.helpers.asset_path("lobby/default_avatar.jpg")
      )
    end
  end

  private

  def find_opponent(user)
    MatchmakingQueue.where.not(user_id: user.id)
                    .order(:created_at)
                    .lock("FOR UPDATE SKIP LOCKED")
                    .first
  end

  def handle_match_found(user, deck_type, opponent_queue)
    opponent = opponent_queue.user
    opponent_queue.destroy!

    # ゲーム作成 (seedはcallbackで設定される)
    game = Game.create!(status: :playing)

    # プレイヤー作成
    GamePlayer.create!(game: game, user: user, role: :host, deck_type: deck_type)
    GamePlayer.create!(game: game, user: opponent, role: :guest, deck_type: opponent_queue.deck_type)

    # ゲーム開始処理
    StartGame.call!(game: game)

    # 対戦相手に通知 (Transaction後に実行するためコンテキストに保存)
    context.broadcast_target = opponent

    context.game = game
  end

  def handle_no_match(user, deck_type)
    MatchmakingQueue.create!(user: user, deck_type: deck_type)
    context.game = nil
  end
end
