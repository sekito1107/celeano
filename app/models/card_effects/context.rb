# 効果実行時のコンテキスト
# 効果が必要とする全ての情報を提供する
module CardEffects
  class Context
    attr_reader :source_card, :target, :game, :game_player, :timing

    def initialize(source_card:, target: nil, timing:)
      @source_card = source_card
      @target = target
      @timing = timing
      @game = source_card.game
      @game_player = source_card.game_player
    end

    # 狂気状態かどうか
    def insane?
      threshold = source_card.card.threshold_san
      return false if threshold.nil? || threshold <= 0
      game_player.san <= threshold
    end

    # 敵プレイヤー
    def enemy_player
      opponent_role = game_player.host? ? :guest : :host
      @enemy_player ||= game.game_players.find_by(role: opponent_role)
    end

    # 敵のボード上のユニット
    def enemy_board_units
      @enemy_board_units ||= GameCard.where(game: game, location: :board)
              .where.not(game_player: game_player)
              .includes(:card)
    end

    # 味方のボード上のユニット
    def ally_board_units
      @ally_board_units ||= GameCard.where(game: game, location: :board, game_player: game_player)
              .includes(:card)
    end

    # 効果発動のログを記録
    def log_effect(event_type, details = {})
      source_card.log_event!(event_type, details.merge(
        card_name: source_card.card.name,
        key_code: source_card.card.key_code,
        timing: timing
      ))
    end
  end
end
