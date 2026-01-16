# frozen_string_literal: true

require "rails_helper"

RSpec.describe FormInputComponent, type: :component do
  let(:form) do
    double("form").tap do |f|
      allow(f).to receive(:label) { |field, label| "<label for=\"#{field}\">#{label}</label>".html_safe }
      allow(f).to receive(:text_field) { |field, **opts| "<input type=\"text\" id=\"#{field}\" />".html_safe }
      allow(f).to receive(:email_field) { |field, **opts| "<input type=\"email\" id=\"#{field}\" />".html_safe }
      allow(f).to receive(:password_field) { |field, **opts| "<input type=\"password\" id=\"#{field}\" />".html_safe }
    end
  end

  describe "レンダリング" do
    it "form-groupクラスを持つ" do
      render_inline(described_class.new(form: form, field: :name, label: "Name", icon: "👤"))

      expect(page).to have_css(".form-group")
    end

    it "ラベルを表示する" do
      render_inline(described_class.new(form: form, field: :name, label: "Codename", icon: "👤"))

      expect(page).to have_css("label", text: "Codename")
    end

    it "アイコンをaria-hidden属性付きで表示する" do
      render_inline(described_class.new(form: form, field: :name, label: "Name", icon: "👤"))

      expect(page).to have_css(".input-icon[aria-hidden='true']", text: "👤")
    end

    it "input-wrapperクラスを持つ" do
      render_inline(described_class.new(form: form, field: :name, label: "Name", icon: "👤"))

      expect(page).to have_css(".input-wrapper")
    end
  end

  describe "#input_method" do
    it "type: :textの場合、:text_fieldを返す" do
      component = described_class.new(form: form, field: :name, label: "Name", icon: "👤", type: :text)

      expect(component.input_method).to eq(:text_field)
    end

    it "type: :emailの場合、:email_fieldを返す" do
      component = described_class.new(form: form, field: :email, label: "Email", icon: "📧", type: :email)

      expect(component.input_method).to eq(:email_field)
    end

    it "type: :passwordの場合、:password_fieldを返す" do
      component = described_class.new(form: form, field: :password, label: "Password", icon: "🔑", type: :password)

      expect(component.input_method).to eq(:password_field)
    end

    it "未知のtypeの場合、:text_fieldを返す" do
      component = described_class.new(form: form, field: :unknown, label: "Unknown", icon: "❓", type: :unknown)

      expect(component.input_method).to eq(:text_field)
    end
  end
end
