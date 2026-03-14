# frozen_string_literal: true

module Torque
  module Admin
    module Engine
      module ClassMethods
        def inspect
          "Torque::Admin[#{admin_application.name.inspect}]"
        end
      end

      def self.included(base)
        adm = base.admin_application
        base.isolate_namespace(adm.base_module)

        base.config.route_set_class = Torque::Admin::RouteSet
      end

      # Allow a quick access to the admin application instance
      def admin_application
        self.class.admin_application
      end

      # Hook into the routes definition process to connect with the admin application instance
      def routes(*)
        return super if routes?

        @routes = config.route_set_class.new_with_config(config, admin_application)
        super
      end
    end
  end
end
