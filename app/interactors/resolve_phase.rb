class ResolvePhase
  include Interactor::Organizer

  # 1. RevealCards: 予約カードを一斉公開（ユニット配置、召喚時効果）
  # 2. ResolveSpells: スペル効果の発動
  # 3. TriggerRoundStartEffects: ラウンド開始時効果
  # 4. ExecuteCombat: 戦闘処理
  # 5. ProcessDeaths: 死亡処理
  # 6. ProcessStatusEffects: 状態異常処理
  # 7. TriggerRoundEndEffects: ラウンド終了時効果（墓地効果を含む）
  organize RevealCards,
           ResolveSpells,
           ProcessDeaths, # スペルによる死亡処理
           TriggerRoundStartEffects,
           ExecuteCombat,
           ProcessDeaths,
           ProcessStatusEffects,
           TriggerRoundEndEffects
end
