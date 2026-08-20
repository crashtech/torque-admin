# frozen_string_literal: true

require_relative 'core/classification'
require_relative 'core/definition'
require_relative 'core/helpers'
require_relative 'core/index'
require_relative 'core/nodes'
require_relative 'core/render'
require_relative 'core/template'

module Torque
  module Elements
    # = Torque Elements \Base
    #
    # An element is the organizer rung of the node ladder: a Node that declares its
    # structural grammar (Core::Classification), hosts its own index of children, loads a
    # config block, and renders by orchestrating its children. The element is its own root.
    #
    # Elements represent the logical structure of a component: the logical representation
    # of a table is its columns, not its rows. Physical output is produced by calling UI
    # helpers directly, never by instantiating intermediate nodes.
    class Base < Node
      include Core::Index
      include Core::Nodes
      include Core::Render
      include Core::Template

      include Core::Helpers
      include Core::Definition
      include Core::Classification

      delegate :view_context, to: '::Torque::Elements::Context'
      delegate :ui, to: :view_context

      setting :max_depth, :min_depth

      class_attribute :abstract_class, instance_accessor: false, instance_predicate: false
      self.abstract_class = true

      class << self
        alias abstract_class? abstract_class

        def inherited(klass)
          super
          klass.abstract_class = false
        end

        def element_type
          @element_type ||= name.demodulize.delete_suffix('Element').underscore.to_sym
        end

        attr_writer :element_type
      end

      alias_method :to_s, :render
      alias_method :to_str, :render
      alias_method :html_safe, :render

      def type
        self.class.element_type
      end

      def inspect
        "#<#{self.class.name} name=#{name.inspect} type=#{type.inspect} id=#{id.inspect} nodes=#{size}>"
      end

      def render_name
        custom = fetch_setting(:render)
        return custom.to_sym if custom.is_a?(Symbol) || custom.is_a?(String)

        type
      end

      def initialize_copy(other)
        super

        remove_instance_variable(:@index) if defined?(@index)
        remove_instance_variable(:@render_methods) if defined?(@render_methods)
        remove_instance_variable(:@current) if defined?(@current)
        remove_instance_variable(:@interface) if defined?(@interface)
      end

      protected

        def apply_context_changes(as = 'root')
          return if name.nil?

          Context.apply_changes(name, as, @options)
          Context.deep_extract_properties(extraction_settings_keys, @options) do |props, _|
            merge_settings(props) if props.present?
          end
        end
    end
  end
end
