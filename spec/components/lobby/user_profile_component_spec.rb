require "rails_helper"

RSpec.describe Lobby::UserProfileComponent, type: :component do
  it "renders the user name" do
    user = build(:user, name: "Test User")
    render_inline(described_class.new(user: user))

    expect(page).to have_text("Test User")
  end

  it "renders the avatar image" do
    user = build(:user)
    render_inline(described_class.new(user: user))

    expect(page).to have_selector("img.user_profile__avatar")
  end
end
