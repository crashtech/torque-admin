# frozen_string_literal: true

require_relative 'resource/active_model'

module Torque
  module Admin
    # = Torque Admin \Resource
    class Resource
      prepend ActiveModel

      delegate :admin_application, to: 'self.class.module_parent'

      attr_reader :name, :controllers, :sections, :widgets, :actions, :primary_handler

      def initialize(name)
        @name = -sanitize_name(name)
        @primary_handler = nil

        @routes = {}
        @sections = Set.new
        @controllers = Set.new
        @widgets = { collection: Set.new, member: Set.new }
        @actions = { batch: Set.new, collection: Set.new, member: Set.new }
      end

      def add_resource_path(action, controller, nesting)
        @routes[-action.to_s] ||= { controller: -controller.to_s, nesting: (nesting || {}).freeze }.freeze
      end

      def enhance_from_route(scope, action_name)
        if (section = scope.annotation(:section))
          @sections << section
        end

        return if (type = scope.annotation(:type)).nil?

        parent = scope[:scope_level_resource]
        list = type == :widget ? @widgets : @actions
        if type != :widget && scope[:path].end_with?(parent.actions_scope)
          list[:batch] << action_name
        elsif scope.scope_level == :new || scope[:path].end_with?(parent.collection_scope)
          list[:collection] << action_name
        else
          list[:member] << action_name
        end
      end

      def resource_class
        @resource_class ||= resource_name.constantize
      end

      def resource_name
        @resource_name ||= -name.classify
      end

      def controller_class
        admin_application.controller_class(controllers.first) if controllers.any?
      end

      ## Basic Info

      def singular_key
        @singular_key ||= -name.split('/').last.singularize
      end

      def singular_title
        singular_key.titleize
      end

      def plural_key
        @plural_key ||= -name.split('/').last.pluralize
      end

      def plural_title
        plural_key.titleize
      end

      def attribute_name(*)
        # Placeholder for future attribute name resolution logic
      end

      def parent_reflections
        raise NoMethodError, 'Subclass must implement the #parent_reflections method'
      end

      ## Paths

      def member_url_options(record, action: :show)
        return if (route = @routes[action.to_s]).nil?
        return if (params = member_params(route, record)).nil?

        params[:controller] = "/#{admin_application.controller_class(route[:controller]).controller_path}"
        params[:action] = action
        params
      end

      def member_url_options!(record, **)
        result = member_url_options(record, **)
        return result unless result.nil?

        raise ActionController::UrlGenerationError, <<~MSG.squish
          Unable to resolve the admin path of #{record.class} (parents not loaded or unknown)
        MSG
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

      protected

        # TODO: We can improve this by resolving the actual route once and re-using it to format the path
        def member_params(route, record)
          controller = admin_application.controller_class(route[:controller])
          params = { controller.primary_param => record.public_send(identifier_of(controller)) }

          nesting = route[:nesting].to_a
          resource = self
          association = nil

          nesting.reverse_each.with_index(1) do |(param_key, controller_path), level|
            record ||= association&.loaded? ? association.target : return

            controller = admin_application.controller_class(controller_path)
            parent = controller.admin_resource
            reflection = resource.parent_reflections[parent.resource_class]

            raise ArgumentError, <<~MSG.squish if reflection.nil?
              Unable to find a belongs to association from #{resource.resource_class} to
              #{parent.resource_class} to resolve the nested path of #{name}
            MSG

            identifier = identifier_of(controller).to_s
            association = record.association(reflection.name)

            if identifier == reflection.association_primary_key.to_s
              params[param_key] = record[reflection.foreign_key]
              record = nil
            elsif association.loaded?
              record = association.target
              params[param_key] = record&.[](identifier)
            end

            params[param_key].nil? ? return : resource = parent
          end

          params
        end

        def identifier_of(controller)
          controller.identified_by || controller.admin_resource.resource_class.primary_key.to_sym
        end

      private

        def sanitize_name(name)
          prefix = admin_application.use_relative_resource_naming? ? '' : "#{admin_application.name}/"
          name.to_s.delete_prefix(prefix)
        end
    end
  end
end
