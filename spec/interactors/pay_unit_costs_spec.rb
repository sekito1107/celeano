require 'rails_helper'

RSpec.describe PayUnitCosts do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let!(:game_player) { create(:game_player, game: game, user: user, san: 10) }
  let(:turn) { create(:turn, game: game, turn_number: 1) }

  before do
    allow(game).to receive(:current_turn_number).and_return(1)
    allow(game.game_players).to receive(:find_by).and_return(game_player)
  end

  context "when moves include spells and units" do
    let(:spell_card) { create(:card, card_type: :spell, cost: "2") }
    let(:unit_card) { create(:card, card_type: :unit, cost: "3") }

    let(:move_spell) { create(:move, turn: turn, user: user, game_card: create(:game_card, card: spell_card, user: user, game: game), cost: 2) }
    let(:move_unit) { create(:move, turn: turn, user: user, game_card: create(:game_card, card: unit_card, user: user, game: game), cost: 3) }

    before do
      move_spell
      move_unit
    end

    it "pays only unit costs silently and records pending costs" do
      # Expect SAN to decrease by unit cost (3) only
      result = nil
      expect {
        result = described_class.call(game: game)
      }.to change { game_player.reload.san }.by(-3)

      # Ensure no logs are created immediately (verifies silent: true)
      expect(game.battle_logs).to be_empty

      # Verify pending costs are recorded in context
      expect(result.pending_costs.values).to include(
        a_hash_including(amount: 3, user_id: user.id)
      )
    end
  end
end
