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
      targets = resolve_targets(game_card, target)
      target_type = determine_target_type(targets)

      ActiveRecord::Base.transaction do
        game_card.log_event!(:spell_activation, {
          card_name: game_card.card.name,
          key_code: game_card.card.key_code,
          target_id: target&.id,
          target_ids: targets.map(&:id),
          target_type: target_type
        })

        # ターゲットが存在するか確認（対象指定スペルかつ、対象が盤面にいない場合は不発）
        # ※全体攻撃系はtargetがnilでも発動するため、single targetの場合のみチェック
        if target && target.location != "board"
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
    # EffectDefinitionからターゲット種別を取得できればベストだが、
    # 現状は簡易的にGameCard#trigger内部で解決されているため、
    # ここではキーコード等から推測するか、汎用的なロジックで再計算する

    # 暫定対応: レジストリから定義を取得してターゲット設定を見る
    effect_definition = CardEffects::Registry.find(game_card.card.key_code)
    return [] unless effect_definition

    # on_playアクションの定義を探す (DSL構造に依存するため少し強引)
    # ※ 本来は EffectDefinition に target_type を返すメソッドを生やすのが正しい
    # 今回は簡易的に実装
    step = find_on_play_step(effect_definition)
    return [] unless step

    target_sym = step.params[:target]
    resolve_target_sym(game_card, selected_target, target_sym)
  end

  def find_on_play_step(definition)
    # Definitionの内部構造にアクセス (privateだがsendで無理やり取得も可能だが、
    # 定義時はブロックとして渡されているため、簡単には取り出せない可能性が高い)
    #
    # 代替案: 定義済みの主要スペルについてハードコードまたはパターンマッチ
    # "tidal_wave" -> :all_enemies
    # "rlyeh_rising" -> :all_allies

    case game_card.card.key_code
    when "tidal_wave" then OpenStruct.new(params: { target: :all_enemies })
    when "rlyeh_rising" then OpenStruct.new(params: { target: :all_allies })
    when "call_of_the_deep", "ocean_embrace", "cthulhu_dream" then OpenStruct.new(params: { target: :selected_target })
    else
      # デフォルトは選択対象とみなす
      OpenStruct.new(params: { target: :selected_target })
    end
  end

  # find_on_play_step が game_card に依存してしまったため修正
  # ここで game_card を引数に取る構造に変えるより、単純な case 文で分岐する
  def resolve_targets(game_card, selected_target)
    case game_card.card.key_code
    when "tidal_wave"
      resolve_target_sym(game_card, selected_target, :all_enemies)
    when "rlyeh_rising"
      resolve_target_sym(game_card, selected_target, :all_allies)
    else
      resolve_target_sym(game_card, selected_target, :selected_target)
    end
  end

  def resolve_target_sym(game_card, selected_target, target_sym)
    game = game_card.game
    owner_player = game_card.game_player
    enemy_player = game.opponent_player_of(owner_player)

    case target_sym
    when :selected_target
      selected_target ? [ selected_target ] : []
    when :all_enemies
      enemy_player.game_cards.where(location: :board)
    when :all_allies
      owner_player.game_cards.where(location: :board)
    when :enemy_player
      [ enemy_player ] # GamePlayerオブジェクト
    when :owner_player
      [ owner_player ]
    else
      []
    end
  end

  def determine_target_type(targets)
    return "unit" if targets.empty?
    targets.first.is_a?(GamePlayer) ? "player" : "unit"
  end
end
