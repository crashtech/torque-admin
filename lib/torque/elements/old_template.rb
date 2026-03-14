# frozen_string_literal: true

module Torque
  module Elements
    class Template
      attr_reader :name, :properties, :aliases

      class << self
        def load_paths
          @load_paths ||= [Pathname.new(__dir__).join('templates')]
        end
      end

      def initialize
        @properties = {}
        @aliases = {}

        load_template('default')
      end

      def register_property(*args, **xargs, &block)
        property = Property.new(*args, **xargs, &block)
        @properties[property.name] = property
      end

      def extend_property(name, *args, **xargs, &block)
        @properties.fetch(name).extend(*args, **xargs, &block)
      end

      def register_aliases_for(attribute, **aliases)
        attribute = attribute.to_s.dasherize.freeze
        sanitized = aliases.each_with_object({}) do |(key, value), hash|
          hash[key.to_sym] = value.to_s
        end

        @aliases[attribute] ||= {}
        @aliases[attribute].merge!(sanitized)
      end

      def register_alias_for(attribute, alias_name, value)
        attribute = attribute.to_s.dasherize.freeze

        @aliases[attribute] ||= {}
        @aliases[attribute][alias_name.to_sym] = value.to_s
      end

      def load_template(template_name)
        self.class.load_paths.reverse_each do |load_path|
          next unless (file = load_path.join("#{template_name}.rb")).exist?

          break instance_eval(file.read, file.to_s)
        end
      end
    end
  end
end
