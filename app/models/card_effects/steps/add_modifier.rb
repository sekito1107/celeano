# 状態異常やバフを付与するステップ
module CardEffects
  module Steps
    class AddModifier < BaseStep
      # 使用例:
      #   add_modifier type: :stun, duration: 1, target: :selected_target
      #   add_modifier type: :attack_buff, value: 3, duration: 1, target: :self
      #   add_modifier type: :poison, value: 2, duration: 3, target: :selected_target

      def call(context)
        modifier_type = params[:type]
        return unless modifier_type

        for_each_target(context) do |target|
          apply_modifier(target, context, modifier_type)
        end
      end

      private

      def apply_modifier(target, context, modifier_type)
        return unless target.is_a?(GameCard)

        target.modifiers.create!(
          effect_type: modifier_type,
          value: params[:value],
          duration: params[:duration],
          modification_type: params[:duration] ? :temporary : :permanent,
          source_name: context.source_card.card.name
        )

        context.log_effect(:effect_modifier_added, {
          target_id: target.id,
          modifier_type: modifier_type,
          value: params[:value],
          duration: params[:duration]
        })
      end
    end
  end
end
