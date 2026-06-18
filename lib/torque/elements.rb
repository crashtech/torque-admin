# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/current_attributes'
require 'active_support/dependencies/autoload'

module Torque
  # = Torque Elements
  module Elements
    extend ActiveSupport::Autoload

    autoload :Frame
    autoload :Templates
    autoload :Controller

    autoload :Base
    autoload :Node
    autoload :Registry
    autoload :Traverse

    autoload :Component

    autoload :Context
    autoload :Helpers
    autoload :UiBuilder
    autoload :HelperConstructor

    autoload_under :handlers do
      autoload :BaseHandler
      autoload :ContentHandler
      autoload :FormatHandler
      autoload :ListHandler
      autoload :MapHandler
      autoload :RefHandler
    end

    autoload_under :nodes do
      autoload :LinkNode
    end

    autoload_under :builders do
      autoload :AliasBuilder
      autoload :HelperBuilder
    end

    class << self
      def logger
        ActionView::Base.logger
      end

      def node_id(value)
        return if value.nil?
        return -value.to_s.tr('_', '-') if value.is_a?(Symbol)
        return -value.map(&method(:node_id)).join('--') if value.is_a?(Array)

        value.to_s.downcase.gsub('.', '--').gsub(/[_\s]/, '-').gsub(/[^-a-z0-9]/, '')
      end

      def attribute_name(name)
        return name if name.is_a?(::String) && name.frozen?

        name.to_s.underscore.dasherize.freeze
      end

      def define_attribute(name, handler)
        raise ::ArgumentError, <<~MSG.squish unless handler.is_a?(BaseHandler)
          Handler #{handler.class.name} for #{name} must be a subclass of BaseHandler.
        MSG

        if name.is_a?(Regexp)
          attributes[:dynamic][name] = handler
        else
          attributes[:static][attribute_name(name)] = handler
        end
      end

      def find_attribute(name)
        attributes[:static].compute_if_absent(name = attribute_name(name)) do
          key = attributes[:dynamic].each_key.find { |pattern| pattern =~ name }
          attributes[:dynamic].fetch(key, default_attribute)
        end
      end

      def static_attribute?(name)
        attributes[:static].key?(name.to_s)
      end

      ## Quick access to configuration methods

      def enable_ui_framework(...)
        UiBuilder.enable_framework(...)
      end

      def add_ui_framework(...)
        UiBuilder.add_framework(...)
      end

      def ui_framework_helper(name)
        Helpers.const_get(name.to_s.classify.sub(/Ui$/, 'UI'))
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
