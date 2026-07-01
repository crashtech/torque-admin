# frozen_string_literal: true

require_relative 'application/default_config'

module Torque
  module Admin
    # = Torque Admin \Application
    class Application
      attr_reader :name, :config, :engine, :mod, :auth_resources

      delegate :title, to: :config

      def initialize(name)
        @name = name.to_sym
        @name = :admin if @name == :default

        @config = DEFAULT_CONFIG.deep_dup
        @engine = Admin::Engine.build(self)
        # TODO: Find a way to allow the admin application be the root application
        @mod = setup_application_module

        clear
        setup_additional_config
      end

      def configure
        yield config
      end

      def mount_options(path, options)
        config.root_path ||= path || options[:at] || options[:path] || name.to_s
        options.except(:path).reverse_merge(as: name, at: config.root_path)
      end

      def base_controller
        @base_controller ||= mod.const_get(:BaseController)
      end

      def ui_builder
        @ui_builder ||= begin
          name, mod_name = ui_theme
          mod = Themes.const_get(mod_name)
          Elements::UiBuilder.add_framework(name, mod).tap(&method(:apply_theme_extensions))
        end
      end

      def clear
        @resources = {}
        @auth_resources = {}
        @ui_builder = nil
        @base_controller = nil
        @engine.mounted = false
        @mod.send(:clear_lazy_constants)
      end

      def finalize_routes!
        @_controllers = nil
        auto_dashboard_route
      end

      def auto_dashboard_route(routes = engine.routes)
        Mapper.new(routes).with_default_scope(routes.default_scope) { dashboard_root }
      end

      def authorization_adapter
        if (value = config.resources.authorization_adapter)
          value == :torque_admin ? 'Authorization' : value.to_s.classify
        end
      end

      def fetch_resource(name)
        @resources[name] ||= mod::Resource.new(name)
      end

      def setup_controller(controller, resource, param)
        return unless (@_controllers ||= Set.new).add?(controller)

        Rails.autoloaders.main.on_load(controller) do |klass, *|
          klass.admin_resource = resource
          klass.identified_by = klass.primary_param = param
        end
      end

      def authenticable_resource!(name, type)
        raise ArgumentError, <<~MSG if @auth_resources.key?(name.to_sym)
          Resource #{name} is already configured for authentication.
        MSG

        @auth_resources[name.to_sym] = type
      end

      def use_relative_resource_naming?
        !!mod.try(:use_relative_model_naming?)
      end

      def inspect
        "#<#{self.class.name} #{<<~INSPECT.chomp}>".squish
          name=#{name == :admin ? ':default' : name.inspect}
          engine=#{engine.name}
          resources=#{@resources.size}
        INSPECT
      end

      private

        def setup_additional_config
          @config.title ||= @name.to_s.titleize
          @config.elements_lookup_context << mod.name

          engine.config.default_scope[:annotations] = {
            admin_application: self,
            authenticated: @config.default_authenticated,
          }

          ActiveSupport::Reloader.before_class_unload(&method(:clear))
        end

        def ui_theme
          @ui_theme ||= ["#{config.theme!}/#{name}", config.theme.to_s.classify.sub(/Ui$/, 'UI')]
        end

        def setup_application_module
          base = config.parent_module!.constantize

          mod_name = name.to_s.camelize.to_sym
          mod = base.const_defined?(mod_name) ? base.const_get(mod_name) : base.const_set(mod_name, Module.new)
          raise ArgumentError, <<~MSG if mod.const_defined?(:Engine)
            The module #{mod.name} already has a constant named Engine.
            Please remove it or choose a different name for your application.
          MSG

          lazy_file = Pathname.new(__dir__).join('application', 'lazy_constants.rb')
          mod.module_eval(lazy_file.read, lazy_file.to_s, 1)
          mod.define_singleton_method(:admin_application, &method(:itself))

          setup_hybrid_module(mod) if config.isolate_namespace.nil?
          engine.isolate_namespace(mod) unless config.isolate_namespace.eql?(false)
          mod.const_set(:Engine, engine)
          mod
        end

        def setup_hybrid_module(mod)
          mod.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
            def table_name_prefix; end
            def use_relative_model_naming?; false; end
          RUBY
        end

        def apply_theme_extensions(klass)
          return if (list = config.theme_extensions).blank?

          Array.wrap(list).each do |extension|
            if extension.respond_to?(:call)
              klass.instance_exec(&extension)
            elsif extension.is_a?(String)
              klass.include(extension.constantize)
            else
              klass.include(extension)
            end
          end
        end
    end
  end
end
