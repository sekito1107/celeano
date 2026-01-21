require "rails_helper"

RSpec.describe Game::PhaseCutInComponent, type: :component do
  it "コンポーネントがエラーなく描画されること" do
    render_inline(described_class.new)
    expect(page).to have_css("div") # 最低限の描画確認
  end
end
