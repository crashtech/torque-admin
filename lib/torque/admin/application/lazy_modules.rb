# frozen_string_literal: true

module Torque
  module Admin
    class Application
      module LazyModules
        MODULES = {
          BaseController: :fetch_base_controller,
          ResourceController: [:build_controller, 'Torque::Admin::ResourceController'],
          DashboardController: [:build_controller, 'Torque::Admin::DashboardController'],
        }.freeze

        class << self
          def fetch_base_controller(mod)
            klass = Class.new(mod.admin_application.config.base_controller!.constantize)
            klass.define_singleton_method(:admin_application, &mod.method(:admin_application))
            klass.include(Admin::BaseController)
            klass.abstract!
            klass
          end

          def build_controller(mod, *extensions)
            klass = Class.new(mod.const_get(:BaseController))
            klass.include(*extensions.map(&:constantize))
            klass.abstract!
            klass
          end
        end

        def const_defined?(name, *)
          MODULES.key?(name) || super
        end

        def const_missing(name)
          return super if (handler, *args = MODULES[name]).nil?

          const_set(name, LazyModules.public_send(handler, self, *args))
        end
      end
    end
  end
end
