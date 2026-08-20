# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Table Element
    class TableElement < BaseElement
      include Elements::ValueReader
      include TableSummaries

      STRUCTURE = { colgroup: :col, thead: :header, tfoot: :footer }.freeze

      node :column, as: :column, renders: false, parts: Elements::ColumnNode::UNITS
      node :actions, as: ButtonsElement, index: false
      node :pagination, as: PaginationElement, one: true

      setting :as, :primary_key, :source_type, :sortable, :paginate, :read_mode, :tbody

      attr_reader :entries

      def initialize(name, entries = [], *, **, &)
        raise ArgumentError, +'Entries must be an enumerable' unless entries.is_a?(Enumerable)

        @entries = entries
        super(name, *, **, &)

        if entries.is_a?(CollectionState)
          change_setting(:sortable, entries.provides?(:sorting)) unless settings?(:sortable)
          change_setting(:paginate, entries.provides?(:paging)) unless settings?(:paginate)
        end

        return unless settings(:paginate, false)

        @pagination = pagination(:pagination, pagination: entries.paging) do
          import_from_pagination
          import_per_options
        end
      end

      ## Define nodes

      def column(identifier, from: nil, **options, &block)
        id = from ? :"#{from}_#{identifier}" : identifier
        options[:as] = block if block
        options[:label] = id unless options.key?(:label)
        options[:sortable] = false unless settings(:sortable, false)
        super(id, source: identifier, from:, **options, &nil)
      end

      def footer(identifier, content: nil, **options, &block)
        content ||= block
        raise ArgumentError, "Column #{identifier} is not defined" if (column = self[identifier]).nil?
        raise ArgumentError, +'A footer takes either a block or an aggregate' if content && options[:aggregate]

        column.summarize(content: content, **options)
      end

      def actions(*actions, column: :actions, defaults: column == :actions, **options, &block)
        entry = entry_proxy
        element = super(column, **options) do |buttons|
          actions = default_actions if actions.empty? && defaults
          actions.each { |action| buttons.item(action, Elements::Deferred.new(:relative_path_for, action, id: entry)) }
          buttons.instance_exec(entry, &block) if block
        end

        self.column(column, label: false, sortable: false, as: proc { element.render_in(reset: true) })
      end

      def each_row(&block)
        (@each_row ||= []) << block
      end

      ## Values

      def value_for(entry, column)
        column = fetch(column) unless column.is_a?(Elements::ColumnNode)
        formatter = column.fetch_setting(:as)
        if formatter.is_a?(Proc)
          value = view_context.instance_exec(entry, &formatter)
          formatter = nil
        else
          value = read_value_for(entry, column.source, from: column.fetch_setting(:from))
        end

        view_context.formatter.format(value, formatter,
          fallback: column.fetch_setting(:fallback),
          attribute: column.source,
          collection: entries,
          entry:,
          **column.formatter_options,
        )
      end

      ## Renders

      def content
        return @content if defined?(@content)

        columns = self.columns
        prefetch_aggregates(columns)
        parts = columns.map { |column| STRUCTURE.each_value.map { |part| column.render_part(part) } }.transpose
        colgroup, thead, tfoot = parts.map { |cells| view_context.safe_join(cells) }

        @content = view_context.safe_join([
          (invoke_part_render(:colgroup, [colgroup], {}) if colgroup),
          (invoke_part_render(:thead, [invoke_part_render(:row, [thead], {})], {}) if thead),
          render_tbody(entries, columns),
          (invoke_part_render(:tfoot, [invoke_part_render(:row, [tfoot], {})], {}) if tfoot && columns.any? { |column| column.fetch_setting(:summary) }),
        ].compact)
      end

      def render_tbody(entries, columns = self.columns, **options)
        rows = entries.map { |entry| render_row(entry, columns) }
        invoke_part_render(:tbody, [view_context.safe_join(rows)], { **settings(:tbody).to_h, **options })
      end

      def render_row(entry, columns = self.columns)
        entry_proxy.__setobj__(entry)
        cells = columns.map { |column| column.render_part(:cell, entry) }
        invoke_part_render(:row, [view_context.safe_join(cells)], row_options(entry))
      end

      ## Overrides

      def implicit_attribute_for?(key, node)
        node =~ :column && key == :label
      end

      alias titlelize_text_for? implicit_attribute_for?

      ## Helpers

      def columns
        children.select { |node| node.is_a?(Elements::ColumnNode) }
      end

      def row_dom_id(entry, primary_key = settings(:primary_key))
        [*settings(:source_type)&.tr('/', '-'), entry_primary_key(entry, primary_key)].join('_')
      end

      def entry_primary_key(entry, primary_key = settings(:primary_key))
        return primary_key if primary_key.is_a?(String)
        return read_value_for(entry, primary_key) if primary_key

        raise ArgumentError, "Table #{name} requires a primary key"
      end

      def entry_proxy
        @entry_proxy ||= SimpleDelegator.new(nil)
      end

      protected

        def sanitized_options!
          super
          change(after: @pagination) if defined?(@pagination)
        end

        def default_read_mode
          entries.is_a?(CollectionState) && entries.relation? ? :call : :json
        end

        def default_actions
          view_context.try(:default_table_actions) || []
        end

        def row_options(entry)
          options = { id: row_dom_id(entry) }
          return options unless defined?(@each_row)

          options['@append'] = @each_row.map { |callback| Elements::Deferred.new(callback, entry) }
          options
        end
    end
  end
end
