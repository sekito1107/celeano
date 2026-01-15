# 戦闘処理を統括するOrganizer
# 攻撃対象決定 → ダメージ解決の順で処理
class ExecuteCombat
  include Interactor::Organizer

  organize DetermineAttackTargets, ResolveDamage
end
