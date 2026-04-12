# frozen_string_literal: true

module Torque
  module Admin
    module BaseController
      extend ActiveSupport::Concern

      include Elements::Frame
      include Elements::Templates
      include Elements::Controller

      delegate :admin_application, :admin_config, :admin_controller_name, :ui_framework, to: :class

      included do
        append_view_path(Admin::APP_DIR.join('views'))
        helper(Admin::ApplicationHelper)
        helper_method(:ui_framework)
        layout(admin_application.name.to_s)
        frame('classic')
      end

      class_methods do
        delegate :config, to: :admin_application, prefix: true

        def element_helper_name(name)
          "#{abstract? || anonymous? ? 'app' : admin_controller_name}_#{name}"
        end

        def ui_framework
          admin_application.ui_builder.framework_name
        end

        def admin_controller_name(namespace: '_')
          name.gsub(/\A(?:#{"#{admin_application.mod.name}::"})?(.*)Controller\z/, '\1').underscore.tr('/', namespace)
        end

        def element_class_name(name)
          name = name.to_s unless name.is_a?(::String)
          name = name.camelize
          name += 'Element' unless name.end_with?('Element')

          admin_application_config.elements_lookup_context.reverse_each.find do |mod_name|
            "#{mod_name}::#{name}".safe_constantize&.then { |klass| return klass }
          end
        end

        ## Quick Elements Definers

        def main_menu(**kwargs, &block)
          element(:main_menu, of_type: :menu, **kwargs, &block)
        end
      end

      def elements_i18n_keys_for(*)
        [
          "#{admin_application.name}.%<name>s.%<type>s.%<id>s",
          "#{admin_application.name}.%<name>s.%<id>s",
          '%<name>s.%<type>s.%<id>s',
          '%<name>s.%<id>s',
        ]
      end
    end
  end
end
