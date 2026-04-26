# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Engine
    class Engine < ::Rails::Engine
      delegate :admin_application, to: :class

      class << self
        attr_reader :admin_application
        attr_accessor :mounted

        alias mounted? mounted

        def build(admin_application)
          klass = Class.new(self)
          klass.instance_variable_set(:@admin_application, admin_application)
          klass.instance.config.admin = admin_application.config
          klass.instance.config.admin_application = admin_application
          klass
        end
      end
    end
  end
end
