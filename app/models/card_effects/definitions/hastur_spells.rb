# ハスター神話スペルカードの効果定義
module CardEffects
  module Definitions
    class HasturSpells < CardEffects::Definition
      # 黄の印: 対象のユニットをスタン状態にする。
      define_effect "yellow_sign" do
        on_play do
          add_modifier target: :selected_target, type: :stun, duration: 1
        end
      end

      # 狂気の囁き: 相手プレイヤーのSAN値を3減少させる。
      define_effect "madness_whisper" do
        on_play do
          modify_san amount: -3, target: :enemy_player
        end
      end

      # カルコサの幻視: 対象のユニットに毒(2)を付与する。
      define_effect "carcosa_vision" do
        on_play do
          add_modifier target: :selected_target, type: :poison, value: 2, duration: 3
        end
      end

      # 王の威光: 敵の全ユニットをスタン状態にする。
      define_effect "kings_presence" do
        on_play do
          add_modifier target: :all_enemies, type: :stun, duration: 1
        end
      end

      # 名状しがたき誓い: 対象のユニットを破壊する。
      define_effect "unspeakable_oath" do
        on_play do
          destroy_unit target: :selected_target
        end
      end
    end
  end
end
