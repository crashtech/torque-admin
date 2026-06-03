# frozen_string_literal: true

module Torque
  module Admin
    module BaseController
      extend ActiveSupport::Concern

      include Elements::Frame
      include Elements::Templates
      include Elements::Controller

      include SettingsController

      delegate :admin_application, :admin_application_config, :admin_controller_name, :ui_framework, to: :class

      included do
        append_view_path Admin::APP_DIR.join('views')
        helper Admin::ApplicationHelper
        helper_method :ui_framework
        layout admin_application.name.to_s
        frame 'classic'

        def _protected_ivars
          super + %i[@_initialized_side_controllers @_slave_of @_route_annotations @_chained_scoped_resource]
        end

        private :_protected_ivars
      end

      class_methods do
        delegate :config, to: :admin_application, prefix: :admin

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

        def main_menu(**, &)
          element(:main_menu, of_type: :menu, detect_current: true, **, &)
        end

        protected

          def generated_handlers_module
            @generated_handlers_module ||= begin
              mod = Module.new
              const_set(:GeneratedHandlers, mod)
              private_constant :GeneratedHandlers
              include(mod)
              mod
            end
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

      protected

        def route_annotations
          @_route_annotations ||= request.get_header('action_dispatch.route').scope_options[:annotations] || {}
        end

        def route_annotation(key)
          route_annotations[key.to_sym]
        end

        def slave_controller?
          defined?(@_slave_of)
        end

        def initialize_as_slave_of(other)
          @_request = other.instance_variable_get(:@_request)
          @_response = other.instance_variable_get(:@_response)
          @_slave_of = other
        end

        def initialized_side_controllers
          @_initialized_side_controllers ||= Hash.new do |hash, name|
            hash[name] = instance = name.to_s.camelize.constantize.allocate
            instance.send(:initialize_as_slave_of, self) if instance.respond_to?(:initialize_as_slave_of, true)
            instance
          end
        end
    end
  end
end
