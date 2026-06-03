# frozen_string_literal: true

module Torque
  module Admin
    module ResourceController
      extend ActiveSupport::Concern

      included do
        append_template_path Rails.root.join('app', 'templates', admin_application.name.to_s, 'resource')
        append_template_path Rails.root.join('app', 'templates', 'resource')
        append_template_path Admin::APP_DIR.join('templates', 'resource')

        stream_from_actions :index, :show if admin_application.config.stream_actions

        alias_element :primary_form, :new_form, :create_form, :edit_form, :update_form
        alias_element :search_form, :index_form

        before_action :eager_load_resource
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

        def eager_load_resource
          params.key?(RESOURCE_PARAM) ? resource : scoped_resource
        end

        def scoped_resource
          (chain = route_annotation(:nesting)).nil? ? default_scoped_resource : chained_scoped_resource(chain)
        end

        def default_scoped_resource
          RESOURCE.resource_class.default_scoped
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

        def nested_scope_from(foreign_member, reflection: nil, macro: :belongs_to)
          reflection ||= RESOURCE.resource_class.reflect_on_all_associations.find do |reflection|
            reflection.klass == foreign_member.class && (macro.nil? || reflection.macro == macro)
          end&.name

          raise <<~MSG unless reflection
            Unable to find a reflection for #{foreign_member.class} within #{RESOURCE.resource_class}
          MSG

          foreign_member.public_send(reflection)
        end
    end
  end
end
