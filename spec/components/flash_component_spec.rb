# frozen_string_literal: true

require "rails_helper"

RSpec.describe FlashComponent, type: :component do
  describe "#render?" do
    context "flashが空の場合" do
      it "falseを返す" do
        component = described_class.new(flash: {})
        expect(component.render?).to be false
      end
    end

    context "alertがある場合" do
      it "trueを返す" do
        component = described_class.new(flash: { alert: "エラー" })
        expect(component.render?).to be true
      end
    end

    context "noticeがある場合" do
      it "trueを返す" do
        component = described_class.new(flash: { notice: "成功" })
        expect(component.render?).to be true
      end
    end
  end

  describe "rendering" do
    context "alertメッセージがある場合" do
      it "alertを表示する" do
        render_inline(described_class.new(flash: { alert: "ログインに失敗しました" }))

        expect(page).to have_css(".flash--alert[role='alert']", text: "ログインに失敗しました")
      end
    end

    context "noticeメッセージがある場合" do
      it "noticeを表示する" do
        render_inline(described_class.new(flash: { notice: "ログインしました" }))

        expect(page).to have_css(".flash--notice[role='status']", text: "ログインしました")
      end
    end

    context "alertが配列の場合" do
      it "各メッセージを個別に表示する" do
        render_inline(described_class.new(flash: { alert: [ "エラー1", "エラー2" ] }))

        expect(page).to have_css(".flash--alert", count: 2)
        expect(page).to have_css(".flash--alert", text: "エラー1")
        expect(page).to have_css(".flash--alert", text: "エラー2")
      end
    end

    context "noticeが配列の場合" do
      it "各メッセージを個別に表示する" do
        render_inline(described_class.new(flash: { notice: [ "成功1", "成功2" ] }))

        expect(page).to have_css(".flash--notice", count: 2)
        expect(page).to have_css(".flash--notice", text: "成功1")
        expect(page).to have_css(".flash--notice", text: "成功2")
      end
    end

    context "flashが空の場合" do
      it "何も表示しない" do
        result = render_inline(described_class.new(flash: {}))

        expect(result.to_html).to be_empty
      end
    end

    context "alertとnotice両方ある場合" do
      it "両方を表示する" do
        render_inline(described_class.new(flash: { alert: "エラー", notice: "情報" }))

        expect(page).to have_css(".flash--alert", text: "エラー")
        expect(page).to have_css(".flash--notice", text: "情報")
      end
    end
  end
end
