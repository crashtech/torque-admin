# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Table Element
    class TableElement < BaseElement
      attr_reader :entries, :columns

      def initialize(name, entries = [], *, **, &)
        raise ArgumentError, +"Entries must be an enumerable" unless entries.is_a?(Enumerable)

        @entries = entries
        super(name, *, **, &)

        @root[:id] ||= node_id(name)
        @root.change!(:@element => self)
        if !settings?(:sortable) && entries.is_a?(CollectionState)
          change_setting(:sortable, entries.provides?(:sort))
        end
      end

      def type = :table

      def element_settings
        super + %i[as sortable read_mode tbody]
      end

      ## Define nodes

      def body(content, **options)
        options[:@content] = content
        add_node(:body, :body, options)
      end

      def column(identifier, label = nil, **options, &block)
        options[:as] = block if block_given?
        options[:accessor] ||= identifier.to_s
        options[:label] ||= label || identifier
        add_node(identifier, :column, options, node_type: :column)
      end

      def row(entry, **options, &)
        identifier = view_context.safe_dom_id(entry)
        options[:id] ||= identifier
        options[:@content] = view_context.capture(&)
        add_node(identifier, :row, options)
      end

      def skeleton(rows:, **options)
        add_node(:skeleton, :skeleton, options.merge(rows: rows, columns: -> { columns.map(&:id) }))
      end

      ## Rows callbacks

      def each_row(&block)
        (@each_row ||= []) << block
      end

      ## Overrides

      def fallback_text_for(key, value, node)
        value.to_s.underscore.titleize if node =~ :column && key == :label
      end

      ## Helpers

      def default_sort_for(*)
        settings(:sortable, false)
      end

      def default_stretch_for(id)
        config = view_context.try(:admin_application_config)
        config&.resources&.title_methods&.include?(id) || false
      end

      ## Others

      def columns
        index.each_value.select { |node| node =~ :column }
      end

      def with_footer?
        settings(:with_footer, false)
      end

      def accessors
        @accessors ||= Elements::Accessors.new(@name, :table_element)
      end

      def append_content_for(part, content = nil, &block)
        @output_flow ||= ActionView::OutputFlow.new
        content = view_context.capture(&block) if block_given?
        @output_flow.append(part.to_sym, content)
      end

      def finalize_content_body(content)
        method = view_context.method(:render_table_content) if view_context.respond_to?(:render_table_content)
        (method || view_context.ui.method(:table_content)).call(content, self, @output_flow)
      ensure
        accessors.finalize!
      end
    end
  end
end

# index as: :table do |t|
#   t.each_row do |row, record|
#     row.class
#   end

#   row_number

#   selection

#   column(:title, strech: true)

#   actions do
#   end

#   footer(:title, content: "")
#   footer(:quantity, as: :numeric, op: :sum)
# end
