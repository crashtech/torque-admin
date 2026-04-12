# frozen_string_literal: true

module Torque
  module Admin
    module ApplicationHelper
      delegate :admin_application, to: :controller

      def app_logo(src = nil)
        src ||= "data:image/svg+xml;base64,#{Base64.strict_encode64(APP_DIR.join('assets/images/logo.svg').read)}"
        ui.logo(src, alt: app_plain_title)
      end

      def app_plain_title
        admin_application.config.title || 'Torque Admin'
      end

      def app_head_title(parts = [app_plain_title], separator: ' - ')
        # TODO: Add page specific title
        ui.render_content_tag(:title, parts.compact.join(separator))
      end

      def app_banner(title = app_plain_title, **kwgargs)
        ui.application_banner(app_logo + title, **kwgargs)
      end

      def app_body_classes
        # TODO: Add additional indicator classes, like unauthenticated
        [admin_application.name, app_controller_class_name, app_action_class_name]
      end

      def app_action_class_name
        "#{action_name.to_s.dasherize}-action"
      end

      def app_controller_class_name
        controller.admin_controller_name(namespace: '--').concat('-controller').dasherize
      end
    end
  end
end
