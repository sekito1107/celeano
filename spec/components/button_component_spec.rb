# frozen_string_literal: true

require "rails_helper"

RSpec.describe ButtonComponent, type: :component do
  describe "レンダリング" do
    it "デフォルトでprimaryバリデーションとsubmitタイプを持つ" do
      render_inline(described_class.new(text: "Click Me"))

      expect(page).to have_css("button.btn.btn-primary[type='submit']", text: "Click Me")
    end

    it "カスタムテキストを表示する" do
      render_inline(described_class.new(text: "Submit"))

      expect(page).to have_content("Submit")
    end

    it "カスタムvariantを適用する" do
      render_inline(described_class.new(text: "Danger", variant: :danger))

      expect(page).to have_css("button.btn.btn-danger")
    end

    it "カスタムtypeを適用する" do
      render_inline(described_class.new(text: "Cancel", type: :button))

      expect(page).to have_css("button[type='button']")
    end

    it "追加の属性を適用する" do
      render_inline(described_class.new(text: "Disabled", disabled: true))

      expect(page).to have_css("button[disabled]")
    end
  end
end
