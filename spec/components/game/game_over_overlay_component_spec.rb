# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::GameOverOverlayComponent, type: :component do
  let(:game) { create(:game) }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:player) { create(:game_player, user: user, game: game) }
  let(:opponent) { create(:game_player, user: other_user, game: game) }

  before do
    game.game_players << player
    game.game_players << opponent
    create(:turn, game: game, turn_number: 1)
  end

  context "ゲームが終了していない場合" do
    it "レンダリングされないこと" do
      render_inline(described_class.new(game: game, current_user: user))
      expect(page).not_to have_css(".game-over-overlay")
    end
  end

  context "ユーザーが勝利した場合" do
    before do
      game.finish_game!(opponent, "HP_DEATH")
    end

    it "勝利画面（Ascension）が表示されること" do
      render_inline(described_class.new(game: game, current_user: user))
      expect(page).to have_css(".game-over-overlay.win")
      expect(page).to have_css(".shatter-container.victory-mode")
      expect(page).to have_content("VICTORY")
      expect(page).to have_content("THE THREAT SUBSIDES")
      expect(page).to have_content("脅威の排除")
    end
  end

  context "ユーザーが敗北した場合（HP Death）" do
    before do
      game.finish_game!(player, "HP_DEATH")
    end

    it "敗北画面（Annihilation）が表示されること" do
      render_inline(described_class.new(game: game, current_user: user))
      expect(page).to have_css(".game-over-overlay.loss")
      expect(page).to have_css(".shatter-container.defeat-mode")
      expect(page).to have_content("DEFEAT")
      expect(page).to have_content("FATAL INJURY")
      expect(page).to have_content("肉体の崩壊")
    end
  end

  context "ユーザーが敗北した場合（Sanity Death）" do
    before do
      game.finish_game!(player, "SAN_DEATH")
    end

    it "Sanity Death画面が表示されること" do
      render_inline(described_class.new(game: game, current_user: user))
      expect(page).to have_css(".game-over-overlay.sanity-death")
      expect(page).to have_css(".shatter-container.sanity-death-mode")
      expect(page).to have_css(".shatter-text", text: "DEFEAT")
      expect(page).to have_css(".shatter-subtitle", text: "DESCENDED INTO MADNESS")
      expect(page).to have_content("発狂")
    end
  end

  context "ゲームが引き分けの場合（Mutual Insanity - SAN）" do
    before do
      game.finish_draw!("SAN_DRAW")
    end

    it "Mutual Insanity画面が表示されること" do
      render_inline(described_class.new(game: game, current_user: user))

      expect(page).to have_css(".game-over-overlay.mutual-insanity")
      expect(page).to have_css(".shatter-container.mutual-insanity-mode")

      expect(page).to have_css(".shatter-text", text: "DRAW")
      expect(page).to have_css(".shatter-subtitle", text: "MUTUAL INSANITY")
      expect(page).to have_css(".shatter-subsubtitle", text: "狂気への共振")
    end
  end

  context "ゲームが引き分けの場合（Mutual Destruction - HP）" do
    before do
      game.finish_draw!("HP_DRAW")
    end

    it "Mutual Destruction画面が表示されること" do
      render_inline(described_class.new(game: game, current_user: user))

      expect(page).to have_css(".game-over-overlay.mutual-destruction")
      expect(page).to have_css(".shatter-container.mutual-destruction-mode")

      expect(page).to have_css(".shatter-text", text: "DRAW")
      expect(page).to have_css(".shatter-subtitle", text: "MUTUAL DESTRUCTION")
      expect(page).to have_css(".shatter-subsubtitle", text: "焦土と灰燼")
    end
  end
end
