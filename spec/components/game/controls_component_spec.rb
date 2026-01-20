# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::ControlsComponent, type: :component do
  let(:user) { create(:user) }
  let(:game) { create(:game) }
  let(:game_player) { create(:game_player, game: game, user: user) }

  it "renders the ready button" do
    render_inline(described_class.new(game_player: game_player))

    expect(page).to have_css("#field-controls")
    expect(page).to have_button("READY")
  end

  it "renders WAIT when ready" do
    game_player.update!(ready: true)
    render_inline(described_class.new(game_player: game_player))

    expect(page).to have_button("WAIT", disabled: true)
  end
end
