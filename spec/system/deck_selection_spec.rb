require 'rails_helper'

RSpec.describe "デッキ選択機能", type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:selenium_chrome_headless)
    login_as(user)
  end

  it "ロビーでデッキを選択できること" do
    visit lobby_path

    expect(page).to have_select("deck-select", selected: "Cthulhu")

    select "Hastur", from: "deck-select"
    expect(page).to have_selector(".deck-selector[data-status='saved']")

    visit lobby_path
    expect(page).to have_select("deck-select", selected: "Hastur")

    expect(user.reload.selected_deck).to eq("hastur")
  end
end
