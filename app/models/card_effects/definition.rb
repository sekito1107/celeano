# 効果定義の基底クラス
# カードごとの効果はこのクラスを継承して定義する
module CardEffects
  class Definition
    class << self
      # このクラスで定義された全ての効果を返す
      def effects
        @effects ||= {}
      end

      # 効果を定義する
      # @param key_code [String] カードのkey_code
      # @param block [Proc] 効果定義ブロック
      def define_effect(key_code, &block)
        if effects.key?(key_code)
          raise ArgumentError, "CardEffects: key_code '#{key_code}' is already defined"
        end
        builder = EffectBuilder.new
        builder.instance_eval(&block)
        effects[key_code] = builder.build
      end
    end

    # 効果ビルダー - DSL構文をパースして効果を構築
    class EffectBuilder
      TIMINGS = %i[
        on_play
        on_attack
        on_death
        on_round_start
        on_round_end
        on_graveyard
        on_play_insane
        on_attack_insane
        on_death_insane
        on_round_start_insane
        on_round_end_insane
        on_graveyard_insane
      ].freeze

      def initialize
        @timings = {}
      end

      TIMINGS.each do |timing|
        define_method(timing) do |&block|
          @timings[timing] = StepBuilder.new(&block).steps
        end
      end

      def build
        EffectDefinition.new(@timings)
      end
    end

    # ステップビルダー - 各タイミング内のステップを構築
    class StepBuilder
      def initialize(&block)
        @steps = []
        instance_eval(&block) if block
      end

      attr_reader :steps

      STEP_METHODS = {
        deal_damage: :DealDamage,
        heal_hp: :HealHp,
        draw_cards: :DrawCards,
        add_modifier: :AddModifier,
        destroy_unit: :DestroyUnit,
        return_to_hand: :ReturnToHand,
        modify_san: :ModifySan,
        double_attack: :DoubleAttack
      }.freeze

      STEP_METHODS.each do |method_name, class_name|
        define_method(method_name) do |**params|
          @steps << CardEffects::Steps.const_get(class_name).new(**params)
        end
      end
    end
  end
end
