# frozen_string_literal: true

require 'active_support/dependencies/autoload'
require 'active_support/core_ext/string'

module Torque
  module Elements
    extend ActiveSupport::Autoload

    autoload :Template

    autoload :Property
    autoload :Base

    autoload_under 'handlers' do
      autoload :ListHandler
    end

    class << self
      def attribute_name(value)
        value.to_s.tr('_', '-')
      end

      def enable(setup)
        setup_paths.reverse_each do |setup_path|
          next unless (file = setup_path.join("#{setup}.rb")).exist?

          break instance_eval(file.read, file.to_s)
        end
      end

      def attribute_handler(name)
        return if unmanaged_attributes.include?(name)

        result = static_attributes[name]
        return result if result

        dynamic_attributes.each do |pattern, handler|
          return static_attributes[name] = handler if pattern.match?(name)
        end

        unmanaged_attributes << name
        nil
      end

      def setup_paths
        @setup_paths ||= [Pathname.new(__dir__).join('elements', 'setups')]
      end

      def template_paths
        Template.load_paths
      end

      protected

        def register_unmanaged_attributes(*names)
          unmanaged_attributes.merge(names.map(&method(:attribute_name)))
        end

        def register_attribute(key, handler)
          if key.is_a?(Regexp)
            dynamic_attributes[key] = handler
          else
            static_attributes[attribute_name(key)] = handler
          end
        end

      private

        def unmanaged_attributes
          @unmanaged_attributes ||= Set.new
        end

        def static_attributes
          @static_attributes ||= {}
        end

        def dynamic_attributes
          @dynamic_attributes ||= {}
        end
    end
  end
end
