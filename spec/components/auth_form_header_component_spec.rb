# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthFormHeaderComponent, type: :component do
  describe "レンダリング" do
    it "タイトルを表示する" do
      render_inline(described_class.new(title: "Log In"))

      expect(page).to have_css(".auth-form__title", text: "Log In")
    end

    context "sanity_indicatorが提供された場合" do
      it "sanity indicatorを表示する" do
        render_inline(described_class.new(title: "Log In", sanity_indicator: "Stable"))

        expect(page).to have_css(".sanity-indicator", text: "Stable")
      end
    end

    context "sanity_indicatorが提供されない場合" do
      it "sanity indicatorを表示しない" do
        render_inline(described_class.new(title: "Log In"))

        expect(page).not_to have_css(".sanity-indicator")
      end
    end
  end
end
