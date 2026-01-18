require 'rails_helper'

RSpec.describe ResolvePhase do
  let(:game) { Game.create!(status: :playing) }
  let(:user1) { User.create!(email_address: 'test1@example.com', password: 'password', name: 'P1') }
  let(:user2) { User.create!(email_address: 'test2@example.com', password: 'password', name: 'P2') }
  let(:p1) { GamePlayer.create!(game: game, user: user1, role: :host, hp: 20, san: 20) }
  let(:p2) { GamePlayer.create!(game: game, user: user2, role: :guest, hp: 20, san: 20) }
  let(:turn) { Turn.create!(game: game, turn_number: 1, status: :resolving) }

  # Card Definitions
  let(:unit_card_def) { Card.create!(key_code: 'unit_a', name: 'Unit A', card_type: :unit, hp: 5, attack: 5, cost: 1) }
  let(:damage_spell_def) { Card.create!(key_code: 'call_of_the_deep', name: 'Call of the Deep', card_type: :spell, hp: 0, attack: 0, cost: 2, description: "Deal 3 damage") }

  # Register effect for spell (since we need it to actually do damage)
  # We might need to rely on existing registry if it's seeded, but mocking it is safer for unit test isolation
  # However, for an interactor test, we probably want integration behavior or mocked behavior.
  # Let's try to mock the CardEffects::Registry or rely on seeds if loaded.
  # Since factories/seeds might not be loaded in this specific test environment fully, let's assume implementation works if we set up data right.
  # Note: ResolveSpells calls logic that eventually uses CardEffects::Registry. We verified seeds exist.
  # For this test to work without relying on seeds, we need to stub the effect.

  before do
    # Register a simple damage effect for the test spell using a Double
    effect_definition = double("EffectDefinition")
    allow(effect_definition).to receive(:has_timing?) do |timing|
      timing == :on_play
    end

    allow(effect_definition).to receive(:execute) do |timing, context|
      context.target&.take_damage!(3)
    end

    allow(CardEffects::Registry).to receive(:find).and_call_original
    allow(CardEffects::Registry).to receive(:find).with(damage_spell_def.key_code).and_return(effect_definition)
  end

  describe '.call' do
    let!(:p1_unit) { GameCard.create!(game: game, game_player: p1, user: user1, card: unit_card_def, location: :board, position: :center, current_hp: 5, current_attack: 2) }
    let!(:p2_unit) { GameCard.create!(game: game, game_player: p2, user: user2, card: unit_card_def, location: :board, position: :center, current_hp: 2, current_attack: 5) }

    let!(:spell) do
      GameCard.create!(
        game: game,
        game_player: p1,
        user: user1,
        card: damage_spell_def,
        location: :resolving, # RESERVED
        position: nil,
        target_game_card: p2_unit
      )
    end

    context 'when a reserved spell kills an opponent unit' do
      it 'kills the unit before combat, preventing counter-attack' do
        # Execute Phase
        described_class.call(turn: turn, game: game)

        # Reload state
        p1_unit.reload
        p2_unit.reload
        spell.reload

        # Check Spell Resolution
        expect(spell.location).to eq("graveyard")

        # Check P2 Unit Death (Should be handled by ProcessDeaths BEFORE combat)
        expect(p2_unit.location).to eq("graveyard")
        expect(p2_unit.current_hp).to eq(0)

        # Check P1 Unit Survival (Attack 2 vs HP 5 unit that attack 5)
        # If P2 unit fought back, P1 unit would take 5 damage and HP would be 0.
        # Since P2 unit died before combat, P1 unit should take NO damage.
        expect(p1_unit.current_hp).to eq(5)
      end
    end
  end
end
