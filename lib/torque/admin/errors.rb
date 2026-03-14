# frozen_string_literal: true

module Torque
  module Admin
    # Error class that wraps all the other error classes
    StandardError = Class.new(::StandardError)
  end
end
