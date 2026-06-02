# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Resource
    class Resource
      delegate :admin_application, to: 'self.class.module_parent'

      attr_reader :name, :controllers, :sections, :widgets, :actions, :primary_handler

      delegate :controller_class, to: :primary_handler

      def initialize(name)
        @name = sanitize_name(name).freeze
        @primary_handler = nil

        @sections = Set.new
        @controllers = Set.new
        @widgets = { collection: Set.new, member: Set.new }
        @actions = { collection: Set.new, member: Set.new }
      end

      def enhance_from_route(scope, action_name)
        if (section = scope.annotation(:section))
          @sections << section
        end

        return if (type = scope.annotation(:type)).nil?

        list = type == :widget ? @widgets : @actions
        if scope.scope_level == :action
          list[:member] << action_name
          list[:collection] << action_name
        elsif scope.scope_level == :new || scope.scope_level == :collection
          list[:collection] << action_name
        else
          list[:member] << action_name
        end
      end

      def resource_class
        @resource_class ||= name.classify.constantize
      end

      def singular
         resource_class.respond_to?(:model_name) ? resource_class.model_name.singular : name.split('/').last.singularize
      end

      def plural
         resource_class.respond_to?(:model_name) ? resource_class.model_name.plural : name.split('/').last.pluralize
      end

      def inspect
        "#<#{self.class.name} #{<<~INSPECT.chomp}>".squish
          name=#{name.inspect}
          controllers=#{@controllers.to_a.inspect}
          sections=#{@sections.to_a.inspect}
          widgets=#{@widgets.each_value.map(&:to_a).inspect}
          actions=#{@actions.each_value.map(&:to_a).inspect}
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
