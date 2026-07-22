# frozen_string_literal: true

require_relative 'nodes/rendering'
require_relative 'nodes/textify'

module Torque
  module Elements
    # = Torque Elements \Core Node
    class Node
      CLASS_TYPES = {
        link: 'Torque::Elements::LinkNode',
        column: 'Torque::Elements::ColumnNode',
      }

      attr_reader :id, :type, :options
      attr_accessor :parent

      delegate :[], :[]=, to: :options
      delegate :tag, to: '::Torque::Elements::Context.view_context'

      include Rendering
      include Textify

      alias to_s render
      alias to_str render
      alias html_safe render

      append_render_handler do |node, element = nil, ui: Context.view_context.try(:ui)|
        next if (names = ui&.node_render_names(node, element)).blank?

        names.find do |name|
          Rendering.attempted_render_handlers << "from helpers: `ui.#{name}`"
          break [:render_with_helper, ui.method(name)] if ui.respond_to?(name)
        end
      end

      append_render_handler do |node, element = nil, base: Context.view_context|
        next if (names = base&.node_render_names(node, element)).blank?

        names.find do |name|
          Rendering.attempted_render_handlers << "from helpers: `#{name}`"
          break [:render_with_helper, base.method(name)] if base.respond_to?(name)
        end
      end

      def initialize(id, type, **options)
        @id = id
        @type = type.to_sym

        element = options.delete(:@element)
        @element = element if element

        extract_settings(options)
        @options = options
      end

      def initialize_copy(other)
        super

        @parent = nil
        @options = other.options.deep_dup
        @settings = other.settings.dup if other.settings
        remove_instance_variable(:@children)
      end

      def change(options)
        (@options['@append'] ||= []) << options
      end

      alias append change

      def change!(options)
        @options.merge!(options)
      end

      def sanitized_options
        return @options if @options.frozen?

        sanitized_options!
        @options.freeze
      end

      def children
        @children ||= []
      end

      def branch?
        defined?(@children) && !@children.empty?
      end

      def leaf?
        !branch?
      end

      def of_type?(value)
        value.is_a?(Array) ? type.in?(value) : type == value
      end

      alias =~ of_type?

      def fetch_setting(key, default = nil)
        defined?(@settings) ? @settings.fetch(key, default) : default
      end

      def inspect
        "#<#{self.class.name} id=#{id.inspect} type=#{type.inspect} children=#{children.size} options=#{options.inspect}>"
      end
    end
  end
end
