# frozen_string_literal: true

module Torque
  module Admin
    class Application
      include ActiveSupport::Configurable

      # The root path of the application
      config_accessor :root_path

      # The parent module under which the application's namespace will be defined
      config_accessor :parent_module, default: 'Object'

      attr_reader :name

      delegate :helpers, to: :engine

      def initialize(name)
        @name = name.to_sym
        @name = :admin if @name == :default
        @mounted = false
      end

      def configure
        yield config
      end

      def mounted?
        @mounted
      end

      def mount!(**options)
        return if mounted?

        config.root_path ||= options[:at] || options[:path] || "/#{name}"

        @mounted = true
      end

      def engine
        @engine ||= begin
          klass = Class.new(::Rails::Engine)
          klass.define_singleton_method(:admin_application, &method(:itself))

          klass.extend(Admin::Engine::ClassMethods)
          klass.include(Admin::Engine)

          base_module.const_set('Engine', klass)
        end
      end

      def base_module
        @base_module ||= begin
          base = config.parent_module
          base = base.constantize if base.is_a?(String)

          mod_name = name.to_s.camelize.to_sym
          base.const_set(mod_name, Module.new)
          # Define +table_name_prefix+, so admins don't get such property
          # Define +use_relative_model_naming?= false+
          # Decide about +railtie_helpers_paths+ because accessing public helpers sounds better
        end
      end

      def elements_module
        @elements_module ||= base_module.const_set('Elements', Module.new)
      end
    end
  end
end
