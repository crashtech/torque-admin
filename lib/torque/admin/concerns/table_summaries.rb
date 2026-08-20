# frozen_string_literal: true

module Torque
  module Admin
    module TableSummaries
      INLINE_AGGREGATES = { sum: :sum, count: :count, minimum: :min, maximum: :max }.freeze

      def summary_for(column)
        return unless (summary = column.fetch_setting(:summary))

        content = summary[:content]
        return view_context.collapse_proc(content) if content.is_a?(Proc)
        return content unless content.nil? && summary[:aggregate]

        format_summary(aggregate_for(column), column)
      end

      def aggregate_for(column)
        summary = column.fetch_setting(:summary)
        all = summary[:all].nil? ? entries.try(:relation?) : summary[:all]
        return aggregate_from_entries(summary[:aggregate], column.source) unless all

        raise ArgumentError, <<~MSG.squish unless entries.is_a?(CollectionState)
          Whole-scope aggregates require a collection state, got #{entries.class.name}.
        MSG

        entries.aggregate([summary[:aggregate], column.source]).first
      end

      protected

        def prefetch_aggregates(columns)
          return unless entries.is_a?(CollectionState) && entries.relation?

          requests = columns.filter_map do |column|
            summary = column.fetch_setting(:summary)
            next unless summary && summary[:aggregate] && summary[:content].nil? && summary[:all] != false

            [summary[:aggregate], column.source]
          end

          entries.aggregate(*requests) if requests.any?
        end

        def aggregate_from_entries(aggregate, attribute)
          method_name = INLINE_AGGREGATES.fetch(aggregate) do
            raise ArgumentError, <<~MSG.squish
              Aggregate #{aggregate.inspect} is not supported over an enumerable,
              supported ones are: #{INLINE_AGGREGATES.keys.map(&:inspect).join(', ')}.
            MSG
          end

          values = entries.map { |entry| read_value_for(entry, attribute) }.compact
          values.public_send(method_name)
        end

        def format_summary(value, column)
          summary = column.fetch_setting(:summary)
          view_context.formatter.format(value, summary[:as], **summary[:formatter_options])
        end
    end
  end
end
