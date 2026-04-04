# frozen_string_literal: true

require_relative 'elements'
require_relative 'forms'

require_relative 'admin/version'

module Torque
  # = Torque Admin
  module Admin
    APP_DIR = Pathname.new(__dir__).join('../../app').freeze

    extend ActiveSupport::Autoload

    autoload :Application
    autoload :Engine

    # App-like Constants
    autoload :ApplicationHelper, APP_DIR.join('helpers', 'application_helper')

    autoload :BaseController, APP_DIR.join('controllers', 'base_controller')
    autoload :ResourceController, APP_DIR.join('controllers', 'resource_controller')
    autoload :DashboardController, APP_DIR.join('controllers', 'dashboard_controller')

    # = Torque Admin \Themes
    module Themes
      extend ActiveSupport::Autoload

      autoload :SemanticUI
    end

    class << self
      def [](name)
        instances[name.to_sym] ||= Application.new(name)
      end

      def configure(&block)
        self[:default].configure(&block)
      end

      def instances
        @instances ||= {}
      end
    end
  end
end

require 'torque/admin/errors'
require 'torque/admin/railtie'

ActiveSupport.run_load_hooks(:torque_admin, Torque::Admin)
