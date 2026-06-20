# frozen_string_literal: true

module Torque
  module Admin
    module ItemsFromAction
      def import_items_from_current_action(with_home: true, with_section: true, with_current: false)
        home(with_home) if with_home
        import_from_current_section if with_section

        type = view_context.controller.class.try(:controller_type)
        method_name = "import_from_#{type}_controller"
        send(method_name) if type && respond_to?(method_name, true)

        return unless with_current
        import_item((action = current_action.to_sym), action_label_for(action), { action: }, active: true)
      end

      protected

        def action_label_for(action_name, controller: nil, options: nil)
          controller ||= view_context.controller

          if controller.is_a?(String)
            controller += '_controller' unless controller.end_with?('_controller')
            controller = [view_context.admin_application.name, controller].join('/') unless controller.start_with?('/')
            controller = view_context.controller.send(:initialized_side_controllers)[controller]
          end

          fallback = action_name.to_s.titleize
          options ||= controller.send(:i18n_default_option) if controller.respond_to?(:i18n_default_option, true)

          controller.helpers.app_translate(:breadcrumb, action: action_name, default: fallback, **options) || fallback
        end

        def import_from_current_section
          return if (section = view_context.route_annotation(:section)).nil?
          return if view_context.controller_name == (controller = "#{section}_dashboard")

          import_item(:section, action_label_for(:index, controller:), { controller:, action: :index })
        end

        def import_from_dashboard_controller
          import_item(:index, action_label_for(:index), { action: :index }) unless current_action.index?
        end

        def import_from_resource_controller
          if view_context.controller.instance_variable_defined?(:@_chained_members)
            view_context.controller.instance_variable_get(:@_chained_members).each do |controller, member|
              resource_name = controller.implicit_resource_title_for(member)
              options = controller.send(:i18n_default_option, resource_name:)
              name = controller.controller_name

              label = action_label_for(:index, controller:, options:)
              import_item(options[:plural], label, { controller: name, action: :index })

              label = action_label_for(:show, controller:, options:)
              import_item(options[:singular], label, { controller: name, action: :show, id: member.id })
            end
          end

          return if current_action.index?

          import_item(:index, action_label_for(:index), { action: :index })
          return if !view_context.processing_member_action? || current_action.show?

          import_item(:show, action_label_for(:show), { action: :show })
        end

      private

        def current_action
          @current_action ||= view_context.action_name.inquiry
        end
    end
  end
end
