# ユニットを破壊するステップ
module CardEffects
  module Steps
    class DestroyUnit < BaseStep
      # 使用例:
      #   destroy_unit target: :selected_target

      def call(context)
        for_each_target(context) do |target|
          destroy(target, context)
        end
      end

      private

      def destroy(target, context)
        return unless target.is_a?(GameCard)
        return if target.location_graveyard?

        ActiveRecord::Base.transaction do
          # on_death効果をトリガー（循環を避けるためにフラグで制御）
          target.trigger(:on_death) unless params[:skip_death_trigger]

          target.discard!

          context.log_effect(:effect_destroy, {
            target_id: target.id,
            target_name: target.card.name
          })
        end
      end
    end
  end
end
