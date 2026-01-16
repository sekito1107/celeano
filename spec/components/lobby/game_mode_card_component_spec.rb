require "rails_helper"

RSpec.describe Lobby::GameModeCardComponent, type: :component do
  it "renders the card content" do
    render_inline(described_class.new(
      title: "Test Mode",
      description: "A test description",
      image_path: "lobby/forbidden_library.jpg",
      action_text: "Start"
    ))

    expect(page).to have_text("Test Mode")
    expect(page).to have_text("A test description")
    expect(page).to have_text("Start")
    expect(page).to have_selector("img[alt='Test Mode']")
    expect(page).to have_text("CASUAL")
  end

  it "renders with a custom badge" do
    render_inline(described_class.new(
      title: "Ranked Mode",
      description: "Competitive play",
      image_path: "lobby/forbidden_library.jpg",
      action_text: "Play",
      badge: "RANKED"
    ))

    expect(page).to have_text("RANKED")
  end
end
