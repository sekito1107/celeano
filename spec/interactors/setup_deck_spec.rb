require 'rails_helper'

RSpec.describe SetupDeck do
  let(:game) { create(:game) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let!(:game_player1) { create(:game_player, game: game, user: user1, deck_type: "cthulhu") }
  let!(:game_player2) { create(:game_player, game: game, user: user2, deck_type: "hastur") }

  before do
    # カードをインポートしておく
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
  end

  describe '#call' do
    it '各プレイヤーのデッキタイプに応じてGameCardを生成すること' do
      result = SetupDeck.call(game: game)

      expect(result).to be_success

      # プレイヤー1はクトゥルフデッキ（20枚）
      expect(game_player1.game_cards.count).to eq(20)

      # プレイヤー2はハスターデッキ
      expect(game_player2.game_cards.count).to eq(20)
    end

    it 'デッキタイプが未設定の場合、デフォルトでcthulhuを使用すること' do
      game_player1.update!(deck_type: nil)

      result = SetupDeck.call(game: game)

      expect(result).to be_success
      expect(game_player1.game_cards.count).to eq(20)
    end

    it '存在しないデッキタイプの場合、失敗すること' do
      game_player1.update!(deck_type: "nonexistent")

      result = SetupDeck.call(game: game)

      expect(result).to be_failure
      expect(result.message).to include("Deck definition not found")
    end

    it 'デッキ定義に含まれるカードが存在しない場合、失敗すること' do
      # 意図的にカードを削除してシミュレート
      Card.find_by!(key_code: "deep_one_scout").destroy

      result = SetupDeck.call(game: game)

      expect(result).to be_failure
      expect(result.message).to include("Card not found")
    end
  end
end
