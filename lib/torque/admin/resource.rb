# frozen_string_literal: true

require_relative 'resource/active_model'

module Torque
  module Admin
    # = Torque Admin \Resource
    class Resource
      prepend ActiveModel

      delegate :admin_application, to: 'self.class.module_parent'

      attr_reader :name, :controllers, :sections, :widgets, :actions, :primary_handler

      delegate :controller_class, to: :primary_handler

      def initialize(name)
        @name = sanitize_name(name).freeze
        @primary_handler = nil

        @sections = Set.new
        @controllers = Set.new
        @widgets = { collection: Set.new, member: Set.new }
        @actions = { batch: Set.new, collection: Set.new, member: Set.new }
      end

      def enhance_from_route(scope, action_name)
        if (section = scope.annotation(:section))
          @sections << section
        end

        return if (type = scope.annotation(:type)).nil?

        parent = scope[:scope_level_resource]
        list = type == :widget ? @widgets : @actions
        if scope[:path].end_with?(parent.actions_scope)
          list[:batch] << action_name
        elsif scope.scope_level == :new || scope[:path].end_with?(parent.collection_scope)
          list[:collection] << action_name
        else
          list[:member] << action_name
        end
      end

      def resource_class
        @resource_class ||= name.classify.constantize
      end

      def singular_key
        name.split('/').last.singularize
      end

      def singular_title
        singular_key.titleize
      end

      def plural_key
        name.split('/').last.pluralize
      end

      def plural_title
        plural_key.titleize
      end

      def attribute_name(*)
        # Placeholder for future attribute name resolution logic
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
