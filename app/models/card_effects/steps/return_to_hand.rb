# ユニットを手札に戻すステップ
module CardEffects
  module Steps
    class ReturnToHand < BaseStep
      # 使用例:
      #   return_to_hand target: :selected_target

      def call(context)
        for_each_target(context) do |target|
          return_card(target, context)
        end
      end

      private

      def return_card(target, context)
        return unless target.is_a?(GameCard)
        return unless target.location_board?

        owner = target.game_player
        ActiveRecord::Base.transaction do
          hand_size = owner.game_cards.where(location: :hand).count

          # HPを元に戻す
          target.update!(
            location: :hand,
            position: nil,
            position_in_stack: hand_size,
            current_hp: target.card.hp,
            current_attack: target.card.attack
          )

          # モディファイアをクリア
          target.modifiers.destroy_all

          context.log_effect(:effect_return_to_hand, {
            target_id: target.id,
            target_name: target.card.name,
            owner_id: owner.id
          })
        end
      end
    end
  end
end
