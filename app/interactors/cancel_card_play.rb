class CancelCardPlay
  include Interactor

  def call
    game = context.game
    return if game.finished?

    user = context.user
    game_card_id = context.game_card_id

    # 現在のターンのMoveを取得
    current_turn = game.turns.find_by(turn_number: game.current_turn_number)
    unless current_turn
      context.fail!(message: "現在のターンが見つかりません")
    end

    # 指定されたカードに関連するMoveを検索
    # 条件: 現在のターンの自分のMove
    moves = current_turn.moves.where(game_card_id: game_card_id, user: user)

    if moves.empty?
      context.fail!(message: "キャンセル可能なアクションが見つかりません")
    end

    game_card = moves.first.game_card

    ActiveRecord::Base.transaction do
      # 関連するMoveを全て削除（重複対策）
      moves.destroy_all

      # カードを手に戻す
      game_card.update!(
        location: :hand,
        position: nil, # フィールドの位置情報をクリア
        target_game_card: nil # スペルのターゲット情報をクリア
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    context.fail!(message: "キャンセル処理に失敗しました: #{e.message}")
  end
end
