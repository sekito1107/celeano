# ダメージを与えるステップ
module CardEffects
  module Steps
    class DealDamage < BaseStep
      # 使用例:
      #   deal_damage amount: 3, target: :selected_target
      #   deal_damage amount: 2, target: :all_enemies, insane_bonus: 1

      def call(context)
        amount = calculate_amount(context)
        return if amount <= 0

        ActiveRecord::Base.transaction do
          for_each_target(context) do |target|
            apply_damage(target, amount, context)
          end
        end
      end

      private

      def calculate_amount(context)
        base = params[:amount] || 0
        insane_bonus = context.insane? ? (params[:insane_bonus] || 0) : 0
        base + insane_bonus
      end

      def apply_damage(target, amount, context)
        target.take_damage!(amount)
        context.game.check_player_death!(target) if target.is_a?(GamePlayer)

        context.log_effect(:effect_damage, {
          target_id: target.id,
          target_type: target.class.name,
          amount: amount
        })
      end
    end
  end
end
