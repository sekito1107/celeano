class PayResolvePhaseCosts
  include Interactor

  def call
    game = context.game
    return if game.finished?

    turn = game.turns.find_by(turn_number: game.current_turn_number)
    return unless turn

    # Deferred Logging用のコンテキスト初期化
    context.pending_costs ||= {}

    # このターンにプレイされたカード（Move）を取得
    moves = turn.moves.includes(game_card: [ :card, :game_player ]).includes(:user).order(:id)

    if context.target_card_types
      moves = moves.select { |m| context.target_card_types.include?(m.game_card.card.card_type.to_sym) }
    end

    # 1. 一括支払い (Silent Payment) & 記録
    moves.each do |move|
      cost = move.cost || 0
      next if cost == 0

      game_player = move.game_card.game_player

      # 支払い処理 (ログは出さない)
      game_player.pay_cost!(cost, silent: true)

      # ログ遅延のために記録
      context.pending_costs[move.game_card.id] = {
        amount: cost,
        current_san: game_player.san, # 支払い後の値を記録
        game_player: game_player,
        user_id: game_player.user_id
      }
    end

    # 2. 死亡判定 (Batch Death Check)
    # 全員の支払いが終わった状態でSANを確認
    players = game.game_players.reload
    dead_players = players.select(&:insane?)

    if dead_players.any?
      # 死亡または相打ちが発生する場合
      # アニメーション補完: ゲーム終了前に「カード使用 -> コスト支払い」のログを強制出力する
      flush_fatal_logs(moves)

      # 死亡処理
      if dead_players.size >= 2
        # 相打ち（Mutual Insanity: SAN Draw）
        game.finish_draw!(Game::FINISH_REASONS[:san_draw])
      else
        # 通常の死亡処理
        dead_players.each do |player|
          game.check_player_death!(player)
        end
      end
    end
  end

  private

  def flush_fatal_logs(moves)
    moves.each do |move|
      game_card = move.game_card
      cost_info = context.pending_costs[game_card.id]

      next unless cost_info

      # A. 発動演出 (Cut-In / Reveal)
      if game_card.card.spell?
        # Spell Activation Log (簡易版: ターゲット解決等は省略し、演出に必要な情報のみ出す)
        game_card.log_event!(:spell_activation, {
          card_name: game_card.card.name,
          key_code: game_card.card.key_code,
          image_path: game_card.card.resolved_image_path,
          owner_player_id: game_card.game_player_id,
          user_id: cost_info[:user_id],
          target_ids: [] # 演出用なので空でOK
        })
      elsif game_card.card.unit?
        # Unit Reveal Log
        game_card.log_event!(:unit_revealed, {
          card_id: game_card.id,
          card_name: game_card.card.name,
          key_code: game_card.card.key_code,
          position: move.position,
          owner_player_id: game_card.game_player_id,
          user_id: cost_info[:user_id],
          cost: cost_info[:amount] # Add cost for visual display
        })
      end

      # B. コスト支払い演出
      game_card.game_player.log_event!(:pay_cost, {
        amount: cost_info[:amount],
        current_san: cost_info[:current_san],
        user_id: cost_info[:user_id]
      })

      # 記録から削除 (二重出力防止)
      context.pending_costs.delete(game_card.id)
    end
  end
end
