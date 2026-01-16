require "rails_helper"

RSpec.describe Matchmaking::FlavorTextComponent, type: :component do
  it "コントローラー付きでフレーバーテキストが表示されること" do
    render_inline(described_class.new)

    expect(page).to have_selector(".matchmaking-flavor")
    expect(page).to have_selector("[data-controller='matchmaking-flavor']")
    expect(page).to have_selector(".flavor-text")
  end
end
