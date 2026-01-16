# frozen_string_literal: true

class ButtonComponent < ApplicationComponent
  def initialize(text:, type: :submit, variant: :primary, **options)
    @text = text
    @type = type
    @variant = variant
    @options = options
  end

  attr_reader :text, :type, :variant, :options

  def css_class
    "btn btn-#{variant}"
  end
end
