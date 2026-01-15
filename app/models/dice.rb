class Dice
  # notation: "1d6", "2d6+3", "5" など
  # seed: Gameが持つ固定のseed値
  # nonce: 何回目のアクションか（乱数のズレを作る）
  def self.roll(notation, seed, nonce)
    return notation.to_i if notation.match?(/\A\d+\z/)

    # "2d6+1" のような形式を解析
    match = notation.match(/(\d+)d(\d+)([\+\-]\d+)?/)

    count = match[1].to_i    # ダイス数
    sides = match[2].to_i    # 面数
    return [ match[3].to_i, 0 ].max if sides == 0 # 0面ダイスは補正値のみ（下限0）

    modifier = match[3].to_i # 補正値 (+1 など)

    # ゲームのseed + アクション回数(nonce) で乱数生成器を作る
    # これにより、リプレイ時に「同じ場面なら必ず同じ出目」が出る
    rng = Random.new(seed + nonce)

    total = 0
    count.times { total += rng.rand(1..sides) }

    [ total + modifier, 0 ].max # マイナスにはならない
  end
end
