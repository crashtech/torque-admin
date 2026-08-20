# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      # = Torque Elements \Formatting Helpers
      module Formatting
        extend Formatter::Declarations

        formatters(
          money: :number_to_currency,
          percentage: :number_to_percentage,
          number: :number_with_precision,
          delimited: :number_with_delimiter,
          human: :number_to_human,
          human_size: :number_to_human_size,
          wrap: :data,
        )

        formatters(date: :l, time: :l, datetime: :l, time_ago: :time_ago_in_words, wrap: :time)

        formatters(
          phone: :number_to_phone,
          truncate: :truncate,
          sentence: :to_sentence,
          sanitize: :sanitize,
          strip_tags: :strip_tags,
          mail_to: :mail_to,
        )

        formatter(:ordinal) { |value| value.ordinalize }
        formatter(:humanize) { |value, **options| value.to_s.humanize(**options) }
        formatter(:count) { |collection| collection.size }

        def formatter
          formatting_handler
        end

        def wrap_as_time(content, value)
          tag.time(content, datetime: value.iso8601, title: l(value, format: :long))
        end

        def wrap_as_data(content, value)
          tag.data(content, value: value, title: value)
        end

        def formatter_for(value)
          case value
          when Date then :date
          when Time, DateTime then :datetime
          end
        end

        private

          def formatting_handler
            @formatting_handler ||= Formatter.new(self)
          end
      end
    end
  end
end
