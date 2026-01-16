# frozen_string_literal: true

class AuthFormHeaderComponent < ApplicationComponent
  def initialize(title:, sanity_indicator: nil)
    @title = title
    @sanity_indicator = sanity_indicator
  end

  attr_reader :title, :sanity_indicator
end
