# frozen_string_literal: true

class FormInputComponent < ApplicationComponent
  def initialize(form:, field:, label:, icon:, type: :text, **options)
    @form = form
    @field = field
    @label = label
    @icon = icon
    @type = type
    @options = options
  end

  attr_reader :form, :field, :label, :icon, :type, :options

  def input_method
    case type
    when :email then :email_field
    when :password then :password_field
    when :text then :text_field
    else :text_field
    end
  end
end
