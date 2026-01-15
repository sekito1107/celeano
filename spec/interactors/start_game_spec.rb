require 'rails_helper'

RSpec.describe StartGame, type: :interactor do
  let(:game) { create(:game, seed: 12345) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let!(:player1) { create(:game_player, game: game, user: user1) }
  let!(:player2) { create(:game_player, game: game, user: user2) }

  before do
    # カードをインポートしておく
    Card.delete_all
    cthulhu_cards = YAML.safe_load_file(Rails.root.join("db/data/cards/cthulhu.yml"), permitted_classes: [ Symbol ])
    hastur_cards = YAML.safe_load_file(Rails.root.join("db/data/cards/hastur.yml"), permitted_classes: [ Symbol ])

    (cthulhu_cards.values + hastur_cards.values).each do |card_data|
      Card.find_or_create_by!(key_code: card_data["key_code"]) do |card|
        card.name = card_data["name"]
        card.card_type = card_data["card_type"]
        card.cost = card_data["cost"]
        card.hp = card_data["hp"] || 0
        card.attack = card_data["attack"] || "0"
        card.description = card_data["description"]
      end
    end

    # Deck setup will be handled by SetupDeck interactor called within StartGame
  end


  describe '#call' do
    it '成功すること' do
      result = described_class.call(game: game)

      expect(result).to be_a_success
    end

    it '各プレイヤーに4枚の手札が配られること' do
      described_class.call(game: game)

      expect(player1.hand.count).to eq 4
      expect(player2.hand.count).to eq 4
    end

    it '各プレイヤーのデッキが16枚になること' do
      described_class.call(game: game)

      expect(player1.deck.count).to eq 16
      expect(player2.deck.count).to eq 16
    end

    it '最初のターンが作成されること' do
      result = described_class.call(game: game)

      expect(game.turns.count).to eq 1
      expect(result.turn.turn_number).to eq 1
      expect(result.turn.status).to eq 'planning'
    end

    it 'デッキがシャッフルされること' do
      described_class.call(game: game)

      # position_in_stack が 4〜19 の範囲であることを確認
      expect(player1.deck.pluck(:position_in_stack).sort).to eq((4..19).to_a)

      order1 = player1.deck.order(:position_in_stack).pluck(:card_id)

      # 2回目の実行準備
      # ShuffleDeckは Random.new(game.seed + player.id) を使用するため、
      # 同じシード値を生成するように game2.seed を調整
      game2 = create(:game)
      player1_2 = create(:game_player, game: game2, user: user1)
      create(:game_player, game: game2, user: user2)

      # 同じ乱数シードになるように調整: game.seed + player1.id == game2.seed + player1_2.id
      target_seed = game.seed + player1.id - player1_2.id
      game2.update!(seed: target_seed)

      described_class.call(game: game2)

      order2 = player1_2.deck.order(:position_in_stack).pluck(:card_id)

      # 同じシードなら同じシャッフル結果になることを確認
      expect(order1).to eq(order2)
    end
  end
end
