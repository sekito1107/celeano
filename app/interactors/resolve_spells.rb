class ResolveSpells
  include Interactor

  def call
    game = context.game
    return if game.finished?

    # 解決待ちのスペルを取得（順序は作成順＝プレイ順とする）
    resolving_spells = game.game_cards.joins(:card).includes(:card, :target_game_card).where(location: :resolving).merge(Card.spell).order(:id)

    resolving_spells.each do |game_card|
      break if game.reload.finished?

      target = game_card.target_game_card

      # ターゲット解決（ログ出力用）
      targets, target_sym = resolve_targets(game_card, target)
      target_type = determine_target_type(targets)

      ActiveRecord::Base.transaction do
        game_card.log_event!(:spell_activation, {
          card_name: game_card.card.name,
          key_code: game_card.card.key_code,
          image_path: game_card.card.resolved_image_path,
          owner_player_id: game_card.game_player_id,
          target_id: target&.id,
          target_ids: targets.map(&:id),
          target_type: target_type
        })

        # ターゲットが存在するか確認
        if target_sym == :selected_target && target.nil?
           game_card.log_event!(:spell_fizzle, { reason: "target_missing" })
        elsif target && target.location != "board"
           game_card.log_event!(:spell_fizzle, { reason: "target_missing" })
        else
           game_card.trigger(:on_play, target)
        end

        # スペルは効果発動後に墓地へ
        game_card.discard!
      end
    end
  end

  private

  def resolve_targets(game_card, selected_target)
    # キーコードに応じたターゲット種別の解決
    target_sym = case game_card.card.key_code
    when "tidal_wave" then :all_enemies
    when "rlyeh_rising" then :all_allies
    else :selected_target
    end

    [ resolve_target_sym(game_card, selected_target, target_sym), target_sym ]
  end

  def resolve_target_sym(game_card, selected_target, target_sym)
    game = game_card.game
    owner_player = game_card.game_player
    # opponent_player_of メソッドが存在しないため、直接取得する
    enemy_player = game.game_players.where.not(id: owner_player.id).first

    case target_sym
    when :selected_target
      selected_target ? [ selected_target ] : []
    when :all_enemies
      return [] unless enemy_player
      enemy_player.game_cards.where(location: :board)
    when :all_allies
      owner_player.game_cards.where(location: :board)
    else
      []
    end
  end

  def determine_target_type(targets)
    return "none" if targets.empty?
    targets.first.is_a?(GamePlayer) ? "player" : "unit"
  end
end
