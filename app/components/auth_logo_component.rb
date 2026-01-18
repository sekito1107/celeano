# frozen_string_literal: true

class AuthLogoComponent < ApplicationComponent
  def initialize(title: "Call of Celaeno", subtitle: "— Archive of the Great Old Ones —")
    @title = title
    @subtitle = subtitle
  end

  attr_reader :title, :subtitle
end
