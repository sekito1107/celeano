# HPを回復するステップ
module CardEffects
  module Steps
    class HealHp < BaseStep
      # 使用例:
      #   heal_hp amount: 3, target: :selected_target
      #   heal_hp amount: 1, target: :self

      def call(context)
        amount = params[:amount] || 0
        return if amount <= 0

        for_each_target(context) do |target|
          heal(target, amount, context)
        end
      end

      private

      def heal(target, amount, context)
        return unless target.is_a?(GameCard)

        # カードの最大HPを超えないように回復
        max_hp = target.card.hp
        new_hp = [ target.current_hp + amount, max_hp ].min
        actual_heal = new_hp - target.current_hp

        return unless actual_heal > 0

        target.update!(current_hp: new_hp)

        context.log_effect(:effect_heal, {
          target_id: target.id,
          amount: actual_heal,
          new_hp: new_hp
        })
      end
    end
  end
end
