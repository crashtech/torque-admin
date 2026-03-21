# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/dependencies/autoload'

module Torque
  module Elements
    extend ActiveSupport::Autoload

    autoload :Frame
    autoload :Helpers
    autoload :Templates

    autoload :UiBuilder
    autoload :HelperConstructor

    autoload_under :handlers do
      autoload :BaseHandler
      autoload :ContentHandler
      autoload :ListHandler
      autoload :NameHandler
      autoload :RefHandler
    end

    autoload_under :builders do
      autoload :AliasBuilder
      autoload :HelperBuilder
    end

    ## Settings
    mattr_accessor :auto_compile_on_define, default: false

    class << self
      def logger
        ActionView::Base.logger
      end

      def attribute_name(name)
        name.to_s.underscore.dasherize
      end

      def define_attribute(name, handler)
        raise ::ArgumentError, <<~MSG.squish unless handler.is_a?(BaseHandler)
          Handler #{handler.class.name} for #{name} must be a subclass of BaseHandler.
        MSG

        if name.is_a?(Regexp)
          attributes[:dynamic][name] = handler
        else
          attributes[:static][attribute_name(name).freeze] = handler
        end
      end

      def find_attribute(name)
        attributes[:static].compute_if_absent((name = attribute_name(name)).freeze) do
          key = attributes[:dynamic].each_key.find { |pattern| pattern =~ name }
          attributes[:dynamic].fetch(key, default_attribute)
        end
      end

      def static_attribute?(name)
        attributes[:static].key?(name.to_s)
      end

      ## Quick access to configuration methods

      def enable_ui_framework(*args, **kwargs)
        UiBuilder.enable_framework(*args, **kwargs)
      end

      def add_ui_framework(*args, **kwargs)
        UiBuilder.add_framework(*args, **kwargs)
      end

      def ui_framework_helper(name)
        Helpers.const_get(name.to_s.classify.sub(/Ui/, 'UI'))
      end

      private

        def attributes
          @attributes ||= { static: Concurrent::Map.new, dynamic: {} }.freeze
        end

        def default_attribute
          @default_attribute ||= BaseHandler.new
        end
    end
  end
end

require_relative 'elements/errors'
require_relative 'elements/railtie'
