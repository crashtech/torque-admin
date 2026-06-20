# frozen_string_literal: true

module Torque
  module Admin
    module ApplicationHelper
      delegate :admin_application, to: :controller

      def app_logo(src = nil)
        if src.nil?
          src = "data:image/svg+xml;base64,#{Base64.strict_encode64(APP_DIR.join('assets/images/logo.svg').read)}"
          ui.logo(src, alt: app_base_title, style: { max_width: '35px', max_height: '35px' })
        else
          ui.logo(src, alt: app_base_title)
        end
      end

      def app_base_title
        admin_application.config.title || 'Torque Admin'
      end

      def app_page_title
        @page_title ||= controller.implicit_page_title
      end

      def app_head_title(parts = [app_page_title, app_base_title], separator: ' - ')
        ui.render_content_tag(:title, parts.compact.join(separator))
      end

      def app_banner(title = app_base_title, **)
        content = [app_logo, title].compact_blank
        ui.application_banner(safe_join(content), **)
      end

      def app_page_banner(title: app_page_title, breadcrumbs: true, actions: true)

      end

      def app_body_classes
        # TODO: Add additional indicator classes, like unauthenticated
        [admin_application.name, app_controller_class_name, app_action_class_name]
      end

      def app_action_class_name
        "#{action_name.to_s.dasherize}-action"
      end

      def app_controller_class_name
        controller.admin_controller_name(namespace: '--') << '-controller'
      end

      def app_translate(key, action: controller.action_name, default: nil, **)
        return if (keys = controller.send(:i18n_default_scopes)).blank?

        keys = keys.map { |scope| "#{format(scope, action:)}.#{key}".to_sym }
        ::I18n.translate(keys.shift, default: [*keys, *default], **)
      end

      def current_page_prefix?(options = nil)
        url_string = URI::RFC2396_PARSER.unescape(url_for(options)).force_encoding(Encoding::BINARY)
        request_uri = URI::RFC2396_PARSER.unescape(request.path).force_encoding(Encoding::BINARY)
        request_uri = +"#{request.protocol}#{request.host_with_port}#{request_uri}" if %r{^\w+://}.match?(url_string)

        remove_trailing_slash!(url_string)
        remove_trailing_slash!(request_uri)

        request_uri.start_with?(url_string)
      end
    end
  end
end
