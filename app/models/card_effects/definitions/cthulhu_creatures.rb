module CardEffects
  module Definitions
    class CthulhuCreatures < CardEffects::Definition
      # ショゴス: 守護（キーワードで処理）- 効果なし

      # ハンティング・ホラー: 速攻（キーワードで処理）- 効果なし

      # ビヤーキー: 速攻（キーワードで処理）- 効果なし

      # スター・スポーン: 守護。狂気時: 攻撃力+3
      define_effect "star_spawn" do
        on_attack_insane do
          add_modifier type: :attack_buff, value: 3, duration: 1, target: :self
        end
      end

      # 食屍鬼: 狂気時: 攻撃時にHP1回復
      define_effect "ghoul" do
        on_attack_insane do
          heal_hp amount: 1, target: :self
        end
      end

      # ナイトゴーント: 召喚時: 敵1体をスタンさせる
      define_effect "night_gaunt" do
        on_play do
          add_modifier type: :stun, duration: 1, target: :selected_target
        end
      end

      # ミ＝ゴ: 狂気時: 攻撃力が2倍になる
      define_effect "mi_go" do
        on_attack_insane do
          double_attack
        end
      end

      # 古のもの: 守護。ラウンド終了時: HP1回復
      define_effect "elder_thing" do
        on_round_end do
          heal_hp amount: 1, target: :self
        end
      end
    end
  end
end
