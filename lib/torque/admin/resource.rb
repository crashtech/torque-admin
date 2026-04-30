# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Resource
    class Resource
      delegate :admin_application, to: 'self.class.module_parent'

      attr_reader :name, :sections, :widgets, :actions, :primary_handler

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
          "#<#{self.class.name} #{<<~INSPECT.chomp}>".squish
            name=#{name.inspect}
            controller=#{controller.inspect}
            #{' singleton=true' if singleton?}
          INSPECT
        end
      end

      def initialize(name)
        @name = sanitize_name(name).freeze
        @primary_handler = nil

        @sections = Set.new
        @widgets = { collection: Set.new, member: Set.new }
        @actions = { collection: Set.new, member: Set.new }
        @handlers = {}
      end

      def enhance_from_route(scope, action_name)
        if (section = scope.annotation(:section))
          @sections << section
        end

        list = scope.annotated?(:type, :widget) ? @widgets : @actions
        if scope.scope_level == :action
          list[:member] << action_name
          list[:collection] << action_name
        elsif scope.scope_level == :new || scope.scope_level == :collection
          list[:collection] << action_name
        else
          list[:member] << action_name
        end
      end

      def assign_handler(controller, singleton)
        @handlers[controller] ||= Handler.new(self, controller, singleton).tap do |handler|
          @primary_handler ||= handler
        end
      end

      def inspect
        "#<#{self.class.name} #{<<~INSPECT.chomp}>".squish
          name=#{name.inspect}
          handlers=#{@handlers.size}
          widgets=[#{@widgets.each_value.map(&:size).join(', ')}]
          actions=[#{@actions.each_value.map(&:size).join(', ')}]
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
