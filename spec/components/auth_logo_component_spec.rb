# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthLogoComponent, type: :component do
  describe "デフォルト値でのレンダリング" do
    it "デフォルトのタイトルとサブタイトルを表示する" do
      render_inline(described_class.new)

      expect(page).to have_css(".auth-logo")
      expect(page).to have_css(".logo-title", text: "Call of Celaeno")
      expect(page).to have_css(".logo-subtitle", text: "— Archive of the Great Old Ones —")
    end

    it "data-text属性を含む" do
      render_inline(described_class.new)

      expect(page).to have_css(".logo-title[data-text='Call of Celaeno']")
    end
  end

  describe "カスタム値でのレンダリング" do
    it "カスタムタイトルを表示する" do
      render_inline(described_class.new(title: "Custom Title"))

      expect(page).to have_css(".logo-title", text: "Custom Title")
      expect(page).to have_css(".logo-title[data-text='Custom Title']")
    end

    it "カスタムサブタイトルを表示する" do
      render_inline(described_class.new(subtitle: "Custom Subtitle"))

      expect(page).to have_css(".logo-subtitle", text: "Custom Subtitle")
    end
  end
end
