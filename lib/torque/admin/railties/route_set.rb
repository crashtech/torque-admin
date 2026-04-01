# frozen_string_literal: true

module Torque
  module Admin
    class RouteSet < ActionDispatch::Routing::RouteSet
      attr_reader :admin_application

      # Hook into the pre-configuration to pick the admin application and define it
      def self.new_with_config(config, admin_application)
        super(config).tap { |route_set| route_set.instance_variable_set(:@admin_application, admin_application) }
      end

      private

        def eval_block(block)
          Rails::Mapper.new(self).with_default_scope(default_scope, &block)
        end
    end
  end
end

# action_dispatch.request.path_parameters
