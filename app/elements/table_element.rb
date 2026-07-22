# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Table Element
    class TableElement < BaseElement
      include RowsFromEntries

      alias render_entries_content import_rows_from_entries

      attr_reader :entries

      class << self

      end

      def initialize(name, entries = [], *, **, &)
        raise ArgumentError, +"Entries must be an enumerable" unless entries.is_a?(Enumerable)

        @entries = entries
        super(name, *, **, &)

        @root.change!(:@element => self)
        if !settings?(:sortable) && entries.is_a?(CollectionState)
          change_setting(:sortable, entries.provides?(:sort))
        end
      end

      def type = :table

      def element_settings
        super + %i[as primary_key source_type sortable template read_mode tbody]
      end

      ## Cell value formatter

      def value_for(entry, column, &block)
        column = self[column] unless column.is_a?(Elements::Node)
        formatter = column.fetch_setting(:as)

        block ||= formatter if formatter.is_a?(Proc)
        return view_context.instance_exec(entry, &block) if block
        return read_value_for(entry, column.id) if formatter.nil?

      end

      ## Define nodes

      def body(content, **options)
        options[:@content] = content
        add_node(:body, :body, options)
      end

      def column(identifier, label = nil, **options, &block)
        options[:as] = block if block_given?
        options[:label] ||= label || identifier
        add_node(identifier, :column, options, node_type: :column)
      end

      def row(identifier, content = nil, capture: true, **options, &)
        identifier = row_dom_id(identifier) unless identifier.try(:html_safe?)

        self[identifier] || build_node(identifier, :row, options).tap do |node|
          node.content = content || (capture ? view_context.capture(&) : view_context.safe_join(yield))
        end
      end

      def cell(row_identifier, column_identifier, content = nil, entry: nil, **options, &block)
        column_identifier = column_identifier.id if column_identifier.is_a?(Elements::Node)
        row_identifier = row_dom_id(row_identifier) unless row_identifier.try(:html_safe?)
        identifier = node_id([row_identifier, column_identifier])

        self[identifier] || build_node(identifier, :cell, options).tap do |node|
          node.content = content || value_for(entry, column_identifier, &block)
        end
      end

      def skeleton(rows:, **options)
        options.reverse_merge!(rows: rows, columns: -> { columns.map(&:id) })
        @skeleton = build_node(:skeleton, :skeleton, options)
      end

      ## Rows callbacks

      def run_row_callbacks(*)
        @each_row.each { |callback| view_context.instance_exec(*, &callback) } if row_callbacks?
      end

      def each_row(&block)
        (@each_row ||= []) << block
      end

      def row_callbacks?
        defined?(@each_row)
      end

      ## Overrides

      def implicit_attribute_for?(key, node)
        node =~ :column && key == :label
      end

      alias titlelize_text_for? implicit_attribute_for?

      ## Helpers

      def default_sort_for(*)
        settings(:sortable, false)
      end

      def default_stretch_for(id)
        config = view_context.try(:admin_application_config)
        config&.resources&.title_methods&.include?(id) || false
      end

      def row_dom_id(entry, primary_key = settings(:primary_key))
        [*settings(:source_type)&.tr('/', '-'), entry_primary_key(entry, primary_key)].join('_').html_safe
      end

      def entry_primary_key(entry, primary_key = settings(:primary_key))
        return primary_key if primary_key.is_a?(String)
        return read_value_for(entry, primary_key) if primary_key

        raise ArgumentError, "Table #{name} requires a primary key"
      end

      def read_value_for(entry, attribute, *, reed_mode: settings(:reed_mode))
        case reed_mode
        when NilClass then entry.public_send(attribute)
        when :hash, :object then entry[attribute.to_sym]
        when :json then entry[attribute.to_s]
        when :dig then entry.dig(attribute, *)
        else
          raise ArgumentError, "Unknown reed mode: #{reed_mode.inspect}"
        end
      end

      ## Others

      def collection
        @entries.to_a
      end

      def columns
        index.each_value.select { |node| node =~ :column }
      end

      def with_footer?
        settings(:with_footer, false)
      end

      def append_content_for(part, content = nil, &block)
        @output_flow ||= ActionView::OutputFlow.new
        content = view_context.capture(&block) if block_given?
        @output_flow.append(part.to_sym, content)
      end

      def postamble_root_content(content)
        append_content_for(:content, content) if content.present?
        render_entries_content(stream = defined?(@skeleton))

        flow = @output_flow
        view_context.safe_join([
          render_body_part(:colgroup, flow&.get(:columns)),
          render_body_part(:thead, flow&.get(:headers), true),
          (render_body_part(:tbody, @skeleton.render, false) if stream),
          render_body_part(:tbody, flow&.get(:content), false, settings(:tbody)),
          render_body_part(:tfoot, flow&.get(:footers), true),
        ])
      end

      protected

        def template_path
          return if FalseClass === (value = settings(:template, true))

          TrueClass === value ? settings(:source_type, 'record') : value.to_s
        end

        def render_body_part(tag, content, add_row = false, options = nil)
          return if content.blank?

          if add_row
            node = build_node([tag, :row], :row)
            node.content = content
            content = node.render!
          end

          view_context.content_tag(tag, content, **options)
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

# def row(entry, **options, &)
#   identifier = view_context.safe_dom_id(entry)
#   options[:id] ||= identifier
#   options[:@content] = view_context.capture(&)
#   add_node(identifier, :row, options)
# end

# def table_content(content, element, parts)
#   safe_join([
#     content_tag(:colgroup, parts&.get(:columns)),
#     content_tag(:thead, content_tag(:tr, parts&.get(:headers))),
#     content,
#     view_context.process_table_body(element),
#     (content_tag(:tfoot, content_tag(:tr, parts&.get(:footers))) if element.with_footer?),
#   ])
# end
