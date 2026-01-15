# カード効果のレジストリ
# カード名から効果定義を検索する
module CardEffects
  module Registry
    # 効果定義を持つクラスのリスト
    # 新しい効果定義クラスを追加した場合はここにも追加する
    SOURCES = [
      -> { CardEffects::Definitions::CthulhuSpells },
      -> { CardEffects::Definitions::HasturSpells },
      -> { CardEffects::Definitions::CthulhuCreatures }
    ].freeze

    LOCK = Mutex.new

    class << self
      # カード効果を検索
      # @param key_code [String] カードのkey_code
      # @return [CardEffects::EffectDefinition, nil]
      def find(key_code)
        library[key_code]
      end

      # キャッシュをクリア（テストやリロード時に使用）
      def reset!
        LOCK.synchronize do
          @library = nil
        end
      end

      private

      def library
        LOCK.synchronize do
          @library ||= load_all_effects
        end
      end

      def load_all_effects
        SOURCES.each_with_object({}) do |source_proc, memo|
          source = source_proc.call
          source.effects.each do |key_code, effect|
            if memo.key?(key_code)
              raise ArgumentError, "CardEffects::Registry: key_code '#{key_code}' is already defined in another source"
            end
            memo[key_code] = effect
          end
        end
      end
    end
  end
end
