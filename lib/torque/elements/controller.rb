# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Controller
    module Controller
      extend ActiveSupport::Concern

      included do
        class_attribute :element_settings, instance_accessor: false, instance_predicate: false, default: {}.freeze
        class_attribute :element_aliases, instance_accessor: false, instance_predicate: false, default: {}.freeze
        private_class_method :element_settings=, :element_aliases=

        helper_method :node_render_names, :element_class_for, :element_class_name, :elements_i18n_keys_for
        delegate :element_class_name, :element_class_for, to: :class
      end

      class_methods do
        attr_reader :elements

        def element(name, of_type:, **, &config)
          raise ArgumentError, +'A config block must be provided' unless block_given?

          name = sanitized_element_name(name)
          change_element(name, **)

          (@elements ||= {})[name] = [name, of_type, config]
        end

        def change_element(name, options = nil)
          return unless options

          name = sanitized_element_name(name)
          changed = element_settings.deep_merge(name => options)
          self.element_settings = changed.freeze
          changed[name].freeze
        end

        def alias_element(name, *other_names)
          values = other_names.map { |n| sanitized_element_name(n) }.product([sanitized_element_name(name)]).to_h
          self.element_aliases = element_aliases.merge(values).freeze
        end

        def element_class_for(type)
          klass = type.is_a?(Class) ? type : element_class_name(type)
          return klass if klass.is_a?(Class) && klass <= Torque::Elements::Base

          raise ArgumentError, "#{type} is not a valid element reference"
        end

        def element_class_name(name)
          name = name.to_s unless name.is_a?(::String)
          name = name.camelize
          name += 'Element' unless name.end_with?('Element')
          name.safe_constantize
        end

        protected

          def sanitized_element_name(name)
            name.is_a?(::String) ? name.to_s.underscore.to_sym : name
          end
      end

      def node_render_names(node, element = nil)
        return unless element
        return [-"render_#{element.name}"] if node =~ :root

        [-"render_#{element.name}_#{node.type}", -"render_#{element.type}_#{node.type}"]
      end

      def elements_i18n_keys_for(*)
        ['%<name>s.%<type>s.%<id>s', '%<name>s.%<id>s']
      end

      def fetch_element(name, *, **)
        (Context.registry || Registry.new(self)).fetch(name, *, **)
      end
    end
  end
end
