require 'rails_helper'

RSpec.describe "Cost Flow Integration", type: :interactor do
  let(:user) { create(:user) }
  let(:game) { create(:game, seed: 12345) } # Fix seed for deterministic dice
  let(:player) { create(:game_player, game: game, user: user, san: 50) }
  let(:turn) { create(:turn, game: game) }

  # Card with complex cost
  let(:card) { create(:card, :unit, cost: "1d6+2", name: "Complex Cost Unit") }
  let(:game_card) { create(:game_card, game: game, game_player: player, card: card, location: :hand) }

  before do
    # Ensure moves are handled correctly
  end

  it "calculates cost, pays it, and logs correct cost in unit_revealed" do
    # 1. Play Card (ValidatePlay -> CreateMove)
    play_context = PlayCard.call(
      game: game,
      game_player: player,
      game_card: game_card,
      turn: turn,
      position: "center"
    )

    expect(play_context).to be_a_success
    move = play_context.move

    # 1d6+2 with seed 12345/nonce 0 might be specific
    # Dice logic:
    # rng = Random.new(12345 + 0)
    # total = rng.rand(1..6) + 2
    # Let's check what it is
    expected_cost = move.cost
    expect(expected_cost).to be > 0

    # Move card to resolving (as if scheduled)
    game_card.update!(location: :resolving)

    # 2. Resolve Phase (PayUnitCosts -> PayResolvePhaseCosts -> RevealCards)
    # We need to simulate ResolvePhase flow

    # PayUnitCosts
    pay_context = PayUnitCosts.call(game: game)
    expect(pay_context).to be_a_success
    pending_costs = pay_context.pending_costs

    expect(pending_costs).not_to be_nil
    expect(pending_costs[game_card.id]).to include(amount: expected_cost)

    # RevealCards
    # Mock context for RevealCards with pending_costs
    # We can't easily chain contexts unless we use ResolvePhase,
    # but we can call RevealCards manually passing pending_costs

    reveal_context = RevealCards.call(game: game, pending_costs: pending_costs)
    expect(reveal_context).to be_a_success

    # Verify log creation
    log = BattleLog.where(event_type: :unit_revealed).last
    expect(log).not_to be_nil
    expect(log.details["card_id"]).to eq(game_card.id)
    # JSON stores keys as strings, values might be integers or strings
    # Check both string/integer just in case or assume simple equality
    expect(log.details["cost"]).to eq(expected_cost)
  end
end
