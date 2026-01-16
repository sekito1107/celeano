class JoinMatchmaking
  include Interactor

  def call
    user = context.user
    deck_type = context.deck_type

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
    StartGame.call(game: game)

    context.game = game
  end

  def handle_no_match(user, deck_type)
    MatchmakingQueue.create!(user: user, deck_type: deck_type)
    context.game = nil
  end
end
