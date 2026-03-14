# frozen_string_literal: true

module Torque
  module Admin
    configure do |config|
    end

    # This is the logger for all the operations for Admin
    def self.logger
      config.logger ||= ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
    end
  end
end
