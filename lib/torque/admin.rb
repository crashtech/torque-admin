# frozen_string_literal: true

require 'active_support/configurable'

require_relative 'elements'
require_relative 'forms'

require_relative 'admin/version'

module Torque
  module Admin
    extend ActiveSupport::Autoload

    include ActiveSupport::Configurable

    autoload :Application
    autoload :Engine

    class << self
      def [](name)
        instances[name.to_sym] ||= Application.new(name)
      end

      def instances
        @instances ||= {}
      end
    end
  end
end

require 'torque/admin/config'
require 'torque/admin/errors'
require 'torque/admin/railtie'

ActiveSupport.run_load_hooks(:torque_admin, Torque::Admin)
