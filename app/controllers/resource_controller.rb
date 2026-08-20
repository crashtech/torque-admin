# frozen_string_literal: true

module Torque
  module Admin
    module ResourceController
      extend ActiveSupport::Concern

      delegate :resource_class, to: :admin_resource, prefix: :admin

      included do
        class_attribute :admin_resource, instance_writer: false
        class_attribute :primary_param, instance_accessor: false, instance_predicate: false, default: :id
        class_attribute :identified_by, instance_accessor: false, instance_predicate: false

        [
          Rails.root.join('app', 'templates', admin_application.name.to_s, 'resource'),
          Rails.root.join('app', 'templates', 'resource'),
          Admin::APP_DIR.join('templates', 'resource'),
        ].each { |path| append_template_path(path, prefix: admin_application.name.to_s) if path.exist? }

        helper_method :processing_member_action?, :implicit_resource_title, :implicit_resource_title_for

        # stream_from_actions :index, :show if admin_application.config.stream_actions

        prepend_before_action :load_resource, if: :processing_member_action?
        prepend_before_action :find_chain_parents!

        authorize_actions! skip_if_none: true
      end

      include StreamController
      include PageActionsController

      include CollectionController
      include MemberController

      include IndexController
      include ShowController
      include FormController
      include BatchController
      include ActionsController
      include WidgetsController

      class_methods do
        def controller_type
          :resource
        end
      end

      def implicit_page_title(**)
        prefix = action_name.titleize unless action_name.in?(%w[index show])
        suffix = implicit_resource_title if processing_member_action?
        suffix ||= admin_resource.singular_title if instance_variable_defined?(member_ivar_name)
        suffix ||= admin_resource.plural_title
        super(fallback: [*prefix, suffix].join(' '), **)
      end

      def implicit_resource_title
        return @_implicit_resource_title if defined?(@_implicit_resource_title)

        @_implicit_resource_title = implicit_resource_title_for(resource)
      end

      def implicit_resource_title_for(object, using: admin_application_config.resources.title_methods)
        Array.wrap(using).find do |method|
          next unless object.respond_to?(method)

          result = object.public_send(method)
          break result if result.present?
        end
      end

      def implicit_attribute_name(attribute)
        admin_resource.attribute_name(attribute)
      end

      protected

        def processing_member_action?
          params.key?(self.class.primary_param)
        end

        def authorizable_resource
          processing_member_action? ? resource : scoped_resource
        end

        def scoped_resource
          defined?(@_chained_members) ? chained_scoped_resource : default_scoped_resource
        end

        def default_scoped_resource
          admin_resource_class.default_scoped
        end

        def chained_scoped_resource
          nested_scope_from(@_chained_members.values.last)
        end

        def find_chain_parents!(chain = route_annotation(:nesting), values: params, assign: true)
          return unless chain

          @_chained_members = {}
          chain.reduce(nil) do |current, (key, controller)|
            controller = initialized_side_controllers["#{controller}_controller"]

            ivar = controller.send(:member_ivar_name)
            member = instance_variable_defined?(ivar) ? instance_variable_get(ivar) : begin
              current = controller.send(:nested_scope_from, current) if current
              controller.send(:find_member!, values[key], scope: current)
            end

            instance_variable_set(ivar, member) if assign
            @_chained_members[controller] = member
          end
        end

        def nested_scope_from(foreign_member, reflection: nil)
          reflection ||= admin_resource.parent_reflections[foreign_member.class]
          return default_scoped_resource.where(reflection.name => foreign_member) if reflection

          raise "Unable to find a reflection for #{foreign_member.class} within #{admin_resource_class}"
        end

        def i18n_default_option(resource_name: processing_member_action?)
          result = (super || {}).merge(singular: admin_resource.singular_title, plural: admin_resource.plural_title)
          resource_name = implicit_resource_title if TrueClass === resource_name
          result[:resource_name] = resource_name if resource_name
          result
        end

        def fallback_authorization_action
          (request.get? && (processing_member_action? && :show || :index)) || super
        end

        def add_page_action(action_name, href = nil, **)
          return super unless href.nil? || !processing_member_action?
          return super unless admin_resource.actions[:batch].include?(action_name.to_s)

          # TODO: Don't use relative path, just forward the hash for template handling
          href = relative_path_for(action_name, self.class.primary_param => params[self.class.primary_param])
          super(action_name, href, **)
        end
    end
  end
end
