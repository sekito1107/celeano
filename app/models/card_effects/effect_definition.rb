# 効果定義のデータオブジェクト
# 各タイミングに対するステップの配列を保持する
module CardEffects
  class EffectDefinition
    def initialize(timings)
      @timings = timings
    end

    def has_timing?(timing)
      @timings.key?(timing.to_sym)
    end

    def execute(timing, context)
      steps = @timings[timing.to_sym]
      return unless steps

      steps.each do |step|
        step.call(context)
      end
    end
  end
end
