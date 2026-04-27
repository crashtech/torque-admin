# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Resource
    class Resource
      delegate :admin_application, to: 'self.class.module_parent'

      attr_reader :name, :sections, :actions, :primary_handler
      delegate :controller_class, to: :primary_handler

      class Handler < SimpleDelegator
        attr_reader :controller

        def initialize(obj, controller, singleton)
          super(obj)

          @controller = controller
          @singleton = singleton
        end

        def controller_class
          (@controller.underscore.camelize + 'Controller').constantize
        end

        def singleton?
          @singleton
        end

        def inspect
          "#<#{self.class.name} name=#{name.inspect} controller=#{controller.inspect}#{' singleton=true' if singleton?}>"
        end
      end

      def initialize(name)
        @name = sanitize_name(name).freeze
        @primary_handler = nil

        @sections = Set.new
        @actions = { member: Set.new, collection: Set.new, widget: Set.new }
        @handlers = {}
      end

      def enhance_from_route(scope, action_name)
        action_name = action_name.to_s
        @sections << scope[:section] if scope[:section]

        case scope.scope_level
        when :widget then @actions[:widget] << action_name
        when :new, :collection then @actions[:collection] << action_name
        when :member, :resource, :resources then @actions[:member] << action_name
        when :actions
          @actions[:collection] << action_name
          @actions[:member] << action_name
        end
      end

      def fetch_handler(controller, singleton = false)
        @primary_handler ||= @handlers[controller] ||= Handler.new(self, controller, singleton)
      end

      def inspect
        "#<#{self.class.name} #{<<~INSPECT}>".squish
          name=#{name.inspect}
          handlers=#{@handlers.size}
          widgets=#{@actions[:widget].size}
          member_actions=#{@actions[:member].size}
          collection_actions=#{@actions[:collection].size}
        INSPECT
      end

      private

        def sanitize_name(name)
          prefix = admin_application.use_relative_resource_naming? ? '' : "#{admin_application.name}/"
          name.to_s.delete_prefix(prefix)
        end
    end
  end
end
