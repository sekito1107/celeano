# 解決フェーズ開始時に予約済みカードを公開する
# ユニットはボードに配置、スペルはそのまま（効果発動後に墓地へ）
class RevealCards
  include Interactor

  def call
    game = context.game

    ActiveRecord::Base.transaction do
      reveal_units(game)
    end
  end

  private

  def reveal_units(game)
    # 予約中のユニットを取得
    resolving_units = game.game_cards
                          .eager_load(:card)
                          .where(location: :resolving)
                          .merge(Card.unit)
                          .order(:position)

    resolving_units.each do |game_card|
      # ボードに配置（召喚）
      game_card.summon_to!(game_card.position)

      # Deferred Logging: コスト情報をログに含める
      log_details = {
        card_id: game_card.id,
        card_name: game_card.card.name,
        key_code: game_card.card.key_code,
        position: game_card.position,
        owner_player_id: game_card.game_player_id
      }

      cost_info = context.pending_costs&.[](game_card.id)
      if cost_info
        log_details.merge!(
          cost: cost_info[:amount],
          current_san: cost_info[:current_san],
          user_id: cost_info[:user_id]
        )
      end

      # Render card HTML for dynamic reveal (fixes DOM sync issues)
      card_html = ApplicationController.render(
        Game::CardComponent.new(card_entity: game_card, variant: :field)
      )

      game_card.log_event!(:unit_revealed, log_details.merge(card_html: card_html))

      # 召喚時効果をトリガー
      game_card.trigger(:on_play)

      context.pending_costs&.delete(game_card.id) if cost_info
    end
  end
end
