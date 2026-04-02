# frozen_string_literal: true

require_relative 'application/default_config'
require_relative 'application/lazy_modules'

module Torque
  module Admin
    # = Torque Admin \Application
    class Application
      attr_reader :name, :config, :engine, :mod

      delegate :title, to: :config

      def initialize(name)
        @name = name.to_sym
        @name = :admin if @name == :default

        @config = DEFAULT_CONFIG.deep_dup
        @engine = Admin::Engine.build(self)
        @mod = setup_application_module

        setup_additional_config
      end

      def configure
        yield config
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
        @ui_builder = nil
        @base_controller = nil
        LazyModules::MODULES.each_key do |mod_name|
          mod.remove_const(mod_name) if mod.const_defined?(mod_name)
        end
      end

      def inspect
        "#<#{self.class.name} @name=#{name == :admin ? ':default' : name.inspect} @engine=#{engine.name}>"
      end

      private

        def setup_additional_config
          @config.title ||= @name.to_s.titleize
        end

        def ui_theme
          @ui_theme ||= ["#{name}/#{config.theme!}", config.theme.to_s.classify.sub(/Ui$/, 'UI')]
        end

        def setup_application_module
          base = config.parent_module!.constantize

          mod_name = name.to_s.camelize.to_sym
          mod = base.const_defined?(mod_name) ? base.const_get(mod_name) : base.const_set(mod_name, Module.new)
          raise ArgumentError, <<~MSG if mod.const_defined?(:Engine)
            The module #{mod.name} already has a constant named Engine.
            Please remove it or choose a different name for your application.
          MSG

          mod.extend(Application::LazyModules)
          mod.define_singleton_method(:admin_application, &method(:itself))

          setup_hybrid_module(mod) if config.isolate_namespace.nil?
          engine.isolate_namespace(mod) unless config.isolate_namespace.eql?(false)
          mod.const_set(:Engine, engine)
          mod
        end

        def setup_hybrid_module(mod)
          mod.class_eval <<~RUBY, __FILE__, __LINE__ + 1
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
