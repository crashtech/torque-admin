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
        mod = module_parents.find { |mod| break mod if mod.respond_to?(:admin_application) }
        raise +"Unable to determine the admin application" unless mod

        define_singleton_method(:admin_application, &mod.method(:admin_application))
        append_view_path Admin::APP_DIR.join('views')
        helper Admin::ApplicationHelper
        helper_method :ui_framework, :relative_path_for, :relative_url_for, :route_annotation
        layout admin_application.name.to_s
        frame 'classic'

        main_menu { |menu| menu.import_from_routes }

        def _protected_ivars
          super + %i[
            @_initialized_side_controllers @_slave_of @_route_annotations
            @_chained_scoped_resource
          ]
        end

        private :_protected_ivars
      end

      class_methods do
        def admin_application_config
          admin_application.config
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

        def main_menu(**, &)
          element(:main_menu, of_type: :menu, detect_current: true, **, &)
        end

        def secondary_menu(**, &)
          element(:secondary_menu, of_type: :menu, detect_current: true, **, &)
        end

        def profile_menu(**, &)
          element(:profile_menu, of_type: :menu, **, &)
        end

        protected

          def authorize_actions!(skip_if_none: false, only: nil, except: nil)
            if (adapter = admin_application.authorization_adapter)
              include(Admin.const_get("#{adapter}Controller"))
              skip_before_action(:authorize_action!, only: except, except: only) if only || except
            elsif !skip_if_none
              raise +"No authorization adapter configured for #{admin_application.name} application"
            end
          end

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

        def authentication_protected_route?
          route_annotation(:authenticated).present?
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

        # TODO: These two methods don't add too much value in general

        def relative_path_for(action)
          url_for(action:, only_path: true)
        end

        def relative_url_for(action)
          url_for(action:)
        end

        def fallback_authorization_action
          case request.method
          when 'GET'          then :read
          when 'POST'         then :create
          when 'PATCH', 'PUT' then :update
          when 'DELETE'       then :destroy
          end
        end
    end
  end
end
