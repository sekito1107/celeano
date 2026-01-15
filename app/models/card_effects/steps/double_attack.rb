# 攻撃力を2倍にするステップ
module CardEffects
  module Steps
    class DoubleAttack < BaseStep
      # 使用例:
      #   double_attack  # 自分の攻撃力を2倍

      def call(context)
        target = params[:target] ? resolve_target(context) : context.source_card
        return unless target.is_a?(GameCard)

        double_attack_power(target, context)
      end

      private

      def double_attack_power(target, context)
        current_str = target.current_attack.to_s
        new_attack = double_attack_notation(current_str)

        target.update!(current_attack: new_attack)

        context.log_effect(:effect_double_attack, {
          target_id: target.id,
          old_attack: current_str,
          new_attack: new_attack
        })
      end

      def double_attack_notation(notation)
        # 固定値の場合: "5" -> "10"
        return (notation.to_i * 2).to_s if notation.match?(/\A\d+\z/)

        # ダイス記法の場合: "2d6+3" -> "4d6+6"
        match = notation.match(/(\d+)d(\d+)([\+\-]\d+)?/)

        dice_count = match[1].to_i * 2
        sides = match[2].to_i
        modifier = match[3].to_i * 2

        result = "#{dice_count}d#{sides}"
        result += "+#{modifier}" if modifier > 0
        result += modifier.to_s if modifier < 0
        result
      end
    end
  end
end
