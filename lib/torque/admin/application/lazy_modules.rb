# frozen_string_literal: true

module Torque
  module Admin
    class Application
      module LazyModules
        MODULES = {
          Resource: :build_resource_class,

          BaseController: :build_base_controller,
          ResourceController: [:build_controller, 'Torque::Admin::ResourceController'],
          DashboardController: [:build_controller, 'Torque::Admin::DashboardController'],
          SimpleController: :build_simple_controller,
        }.freeze

        class << self
          def build_base_controller(mod)
            klass = Class.new(mod.admin_application.config.base_controller!.constantize)
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

          def build_simple_controller(mod)
            klass = Class.new(mod.const_get(:ResourceController))
            klass.include(SimpleController)
            klass
          end

          def build_resource_class(mod)
            Class.new(Resource)
          end
        end

        def const_missing(name)
          return super if (handler, *args = MODULES[name]).nil?

          const_set(name, LazyModules.public_send(handler, self, *args))
        end
      end
    end
  end
end
