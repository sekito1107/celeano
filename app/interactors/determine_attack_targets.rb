class DetermineAttackTargets
  include Interactor

  def call
    game = context.game
    attack_plan = []

    players = game.game_players.to_a
    # 攻撃順序を視覚的な「列」に合わせてソートする
    # Wave 0: Player Left & Opponent Right (画面左列)
    # Wave 1: Player Center & Opponent Center (中央列)
    # Wave 2: Player Right & Opponent Left (画面右列)

    # 全プレイヤーの盤面カードを取得
    all_attackers = []
    players.each do |player|
      opponent = players.find { |p| p.id != player.id }
      next unless opponent

      player.game_cards.includes(:card, :modifiers).where(location: :board).each do |attacker|
        next unless attacker.can_attack?
        all_attackers << { attacker: attacker, opponent: opponent }
      end
    end

    # ソート順序を定義
    # position: "left", "center", "right"
    # opponent? (player 2): true/false
    #
    # 目標順序:
    # 1. (Player Left, Opponent Right)
    # 2. (Player Center, Opponent Center)
    # 3. (Player Right, Opponent Left)

    sorted_attackers = all_attackers.sort_by do |entry|
      attacker = entry[:attacker]
      # プレイヤー視点でのウェーブインデックスを計算
      # 注意: サーバー側では「誰がPlayerで誰がOpponentか」は相対的だが、
      # ここではホストプレイヤー(先攻?)基準またはID順で一貫性を持たせる必要がある。
      # しかし、ResolveDamageは「全員の攻撃」を処理するので、
      # 「対面同士」が近くにあれば良い。

      # 単純に「左スロット」「中央スロット」「右スロット」という概念でソートするが、
      # 相手プレイヤーの「右スロット」は、自分から見て「左列」である。

      # 簡易的に、GamePlayerのIDが小さい方をPlayer1(手前)、大きい方をPlayer2(奥)と仮定するか、
      # あるいは position 文字列と player_id を組み合わせてスコアリングする。

      # PlayerSide (Lower ID): left=0, center=1, right=2
      # OpponentSide (Higher ID): right=0, center=1, left=2 (Visual Column Index)

      is_player_one = (attacker.game_player_id == players.min_by(&:id).id)

      visual_column = case attacker.position
      when "left"   then is_player_one ? 0 : 2
      when "center" then 1
      when "right"  then is_player_one ? 2 : 0
      else 3
      end

      [ visual_column, attacker.game_player_id ]
    end

    sorted_attackers.each do |entry|
      attacker = entry[:attacker]
      opponent = entry[:opponent]

      resolver = TargetResolver.new(attacker, opponent)
      attack_plan << {
        attacker: attacker,
        target: resolver.resolve,
        target_type: resolver.target_type
      }
    end

    context.attack_plan = attack_plan
  end
end
