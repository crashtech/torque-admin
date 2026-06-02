# frozen_string_literal: true

module Torque
  module Admin
    module ResourceController
      extend ActiveSupport::Concern

      included do
        append_template_path(Rails.root.join('app', 'templates', admin_application.name.to_s, 'resource'))
        append_template_path(Rails.root.join('app', 'templates', 'resource'))
        append_template_path(Admin::APP_DIR.join('templates', 'resource'))

        stream_from_actions(:index, :show) if admin_application.config.stream_actions
      end

      include StreamController

      include CollectionController
      include MemberController

      include IndexController
      include ShowController
      include FormController
      include ActionsController
      include WidgetsController

      protected

        def scoped_resource
          (chain = route_annotation(:nesting)).nil? ? default_scoped_resource : chained_scoped_resource(chain)
        end

        def default_scoped_resource
          RESOURCE.resource_class.default_scoped
        end

        def chained_scoped_resource(chain)
          nested_scope_from(find_chain_parent!(chain))
        end

        def find_chain_parent!(chain, values: params, assign: true)
          chain.reduce(nil) do |current, (key, controller)|
            controller = initialized_side_controllers["#{controller}_controller"]
            current = controller.send(:nested_scope_from, current) if current

            member = controller.send(:find_member!, values[key], scope: current)
            instance_variable_set(controller.send(:member_ivar_name), member) if assign
            member
          end
        end

        def nested_scope_from(foreign_member)
          # TODO: Find a association from the member to the resource class and return it as a scope
        end
    end
  end
end
