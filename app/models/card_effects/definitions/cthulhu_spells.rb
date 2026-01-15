# クトゥルフ神話スペルカードの効果定義
module CardEffects
  module Definitions
    class CthulhuSpells < CardEffects::Definition
      # 深淵の呼び声: 対象のユニットに3ダメージを与える。
      define_effect "call_of_the_deep" do
        on_play do
          deal_damage amount: 3, target: :selected_target
        end
      end

      # ルルイエ浮上: 自分の全ユニットの攻撃力を+2する（このターンのみ）。
      define_effect "rlyeh_rising" do
        on_play do
          add_modifier target: :all_allies, type: :attack_buff, value: 2, duration: 1
        end
      end

      # 海の抱擁: 対象のユニットのHPを3回復する。
      define_effect "ocean_embrace" do
        on_play do
          heal_hp amount: 3, target: :selected_target
        end
      end

      # 津波: 敵の全ユニットに2ダメージを与える。
      define_effect "tidal_wave" do
        on_play do
          deal_damage amount: 2, target: :all_enemies
        end
      end

      # クトゥルフの夢: 対象のユニットをスタン状態にする。
      define_effect "cthulhu_dream" do
        on_play do
          add_modifier target: :selected_target, type: :stun, duration: 1
        end
      end
    end
  end
end
