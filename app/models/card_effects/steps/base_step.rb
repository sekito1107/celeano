# 効果ステップの基底クラス
# 全ての具体的な効果ステップはこのクラスを継承する
module CardEffects
  module Steps
    class BaseStep
      def initialize(**params)
        @params = params
      end

      # 効果を実行する
      # @param context [CardEffects::Context] 実行コンテキスト
      def call(context)
        raise NotImplementedError, "#{self.class}#call must be implemented"
      end

      protected

      attr_reader :params

      # ターゲット解決のヘルパー
      def resolve_target(context)
        target_type = params[:target] || :selected_target

        case target_type
        when :selected_target
          context.target
        when :selected_ally
          # 味方ユニットのみ選択可能 (GameCardかつ味方)
          target = context.target
          if target.is_a?(GameCard) && target.game_player == context.game_player
            target
          else
            nil
          end
        when :selected_enemy
          # 敵ユニットのみ選択可能 (GameCardかつ敵)
          target = context.target
          if target.is_a?(GameCard) && target.game_player != context.game_player
            target
          else
            nil
          end
        when :self
          context.source_card
        when :all_enemies
          context.enemy_board_units
        when :all_allies
          context.ally_board_units
        when :enemy_player
          context.enemy_player
        when :owner_player
          context.game_player
        else
          raise ArgumentError, "Unknown target_type: #{target_type}"
        end
      end

      # 配列対応でブロック実行
      def for_each_target(context)
        targets = resolve_target(context)
        return unless targets

        if targets.respond_to?(:each)
          targets.each { |t| yield(t) }
        else
          yield(targets)
        end
      end
    end
  end
end
