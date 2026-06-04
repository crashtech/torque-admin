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

        append_template_path Rails.root.join('app', 'templates', admin_application.name.to_s, 'resource')
        append_template_path Rails.root.join('app', 'templates', 'resource')
        append_template_path Admin::APP_DIR.join('templates', 'resource')

        stream_from_actions :index, :show if admin_application.config.stream_actions

        before_action :load_resource, if: :processing_member_action?

        authorize_actions! skip_if_none: true
      end

      include StreamController

      include CollectionController
      include MemberController

      include IndexController
      include ShowController
      include FormController
      include BatchController
      include ActionsController
      include WidgetsController

      protected

        def processing_member_action?
          params.key?(self.class.primary_param)
        end

        def authorizable_resource
          processing_member_action? ? resource : scoped_resource
        end

        def scoped_resource
          (chain = route_annotation(:nesting)).nil? ? default_scoped_resource : chained_scoped_resource(chain)
        end

        def default_scoped_resource
          admin_resource_class.default_scoped
        end

        def chained_scoped_resource(chain)
          @_chained_scoped_resource ||= nested_scope_from(find_chain_parent!(chain))
        end

        def find_chain_parent!(chain, values: params, assign: true)
          chain.reduce(nil) do |current, (key, controller)|
            controller = initialized_side_controllers["#{controller}_controller"]

            ivar = controller.send(:member_ivar_name)
            next instance_variable_get(ivar) if instance_variable_defined?(ivar)

            current = controller.send(:nested_scope_from, current) if current
            member = controller.send(:find_member!, values[key], scope: current)
            instance_variable_set(ivar, member) if assign
            member
          end
        end

        def nested_scope_from(foreign_member, reflection: nil, belongs_to_only: true)
          reflection ||= admin_resource_class.reflect_on_all_associations.find do |reflection|
            reflection.klass == foreign_member.class && (!belongs_to_only || reflection.belongs_to?)
          end&.name

          raise <<~MSG unless reflection
            Unable to find a reflection for #{foreign_member.class} within #{admin_resource_class}
          MSG

          foreign_member.public_send(reflection)
        end

        def fallback_authorization_action
          (request.get? && (processing_member_action? && :show || :index)) || super
        end
    end
  end
end
