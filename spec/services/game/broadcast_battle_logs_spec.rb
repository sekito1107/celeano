require "rails_helper"

RSpec.describe Game::BroadcastBattleLogs do
  let(:game) { create(:game) }
  let(:turn) { create(:turn, game: game) }
  let!(:log1) { create(:battle_log, turn: turn, event_type: "attack", details: { foo: "bar" }) }
  let!(:log2) { create(:battle_log, turn: turn, event_type: "damage", details: { amount: 10 }) }

  describe ".call" do
    it "盤面更新とバトルログをブロードキャストすること" do
      expect(GameChannel).to receive(:broadcast_to).with(
        game,
        hash_including(
          type: "game_update",
          board_update: true,
          battle_logs: array_including(
            hash_including(event_type: "attack", details: { "foo" => "bar" }),
            hash_including(event_type: "damage", details: { "amount" => 10 })
          )
        )
      )

      described_class.call(game: game, logs: [ log1, log2 ])
    end
  end
end
