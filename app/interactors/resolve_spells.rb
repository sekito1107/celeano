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

      ActiveRecord::Base.transaction do
        game_card.log_event!(:spell_activation, {
          card_name: game_card.card.name,
          key_code: game_card.card.key_code,
          target_id: target&.id,
          target_ids: target ? [ target.id ] : [], # 将来的な複数対象への布石
          target_type: "unit" # 現状はユニット対象のみだが拡張性を考慮
        })

        # ターゲットが存在するか確認（対象指定スペルかつ、対象が盤面にいない場合は不発）
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
end
