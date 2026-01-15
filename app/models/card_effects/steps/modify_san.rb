# SANを増減するステップ
module CardEffects
  module Steps
    class ModifySan < BaseStep
      # 使用例:
      #   modify_san amount: -2, target: :enemy_player
      #   modify_san amount: -1  # 自分のSANを減らす

      def call(context)
        amount = params[:amount] || 0
        return if amount.zero?

        target_player = resolve_player(context)
        return unless target_player

        apply_san_change(target_player, amount, context)
      end

      private

      def resolve_player(context)
        # デフォルトは自分のプレイヤー
        return context.game_player if params[:target].nil?

        target = resolve_target(context)
        return target if target.is_a?(GamePlayer)
        nil
      end

      def apply_san_change(player, amount, context)
        new_san = [ player.san + amount, 0 ].max

        ActiveRecord::Base.transaction do
          player.update!(san: new_san)

          context.log_effect(:effect_san_change, {
            player_id: player.id,
            amount: amount,
            new_san: new_san
          })
        end
      end
    end
  end
end
