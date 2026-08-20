# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Column Node
    #
    # The logical description of a column: what to read from each entry (+source+), how to
    # format it, and the options of each physical unit it answers through parts. It renders
    # nothing by itself; the owning element pulls its parts.
    class ColumnNode < Node
      UNITS = %i[col header cell footer].freeze

      setting :as, :from, :sortable, :stretch, :width, :fallback, :summary, *UNITS

      attr_reader :source, :formatter_options

      UNITS.each do |unit|
        define_method(unit) do |**options|
          merge_settings(unit => options)
          self
        end
      end

      def initialize(id, type, source: id, **options)
        super(id, type, **options)

        @source = source
        @formatter_options = @options.extract!(*@options.keys.excluding(label_key)).freeze
      end

      def label
        return @label if defined?(@label)

        value = @options.delete(label_key)
        @label = value == false ? nil : text_for(label_key, default: value)
      end

      def unit_options(unit)
        fetch_setting(unit, {})
      end

      def col_options
        { stretch: stretch?, width: fetch_setting(:width), **unit_options(:col) }
      end

      def header_options
        return unit_options(:header) unless sortable?

        { sortable: true, **sorting_options, **unit_options(:header) }
      end

      def sorting_options
        sorting = element.entries.sorting
        reflection, attribute = sort_key
        { direction: sorting.values[[reflection, attribute]], href: sorting.href.call(attribute, reflection:) }
      end

      def summarize(content: nil, aggregate: nil, all: nil, as: nil, **formatter_options)
        merge_settings(summary: { content:, aggregate:, all:, as:, formatter_options: }.freeze)
        self
      end

      def sortable?
        value = fetch_setting(:sortable)
        return !!value unless value.nil?

        reflection, attribute = sort_key
        element.entries.sorting.sortable.call(attribute, reflection:)
      end

      def sort_key
        @sort_key ||= begin
          value = fetch_setting(:sortable)
          attribute = value.is_a?(Symbol) || value.is_a?(String) ? value : source
          [fetch_setting(:from)&.to_s, attribute.to_s]
        end
      end

      def stretch?
        return false if fetch_setting(:from)

        value = fetch_setting(:stretch)
        return !!value unless value.nil?

        config = Context.view_context.controller.try(:admin_application_config)
        config&.resources&.title_methods&.include?(source) || false
      end

      def dispatch_part(part, *args, **options)
        super(part, *part_arguments(part, *args), **part_options(part), **options)
      end

      def render(outer: false)
      end

      def to_s
        ''
      end

      alias to_str to_s
      alias html_safe to_s

      protected

        def part_arguments(part, *args)
          case part
          when :col then []
          when :header then [label]
          when :cell then [element.value_for(args.first, self)]
          when :footer then [element.summary_for(self)]
          else args
          end
        end

        def part_options(part)
          case part
          when :col then col_options
          when :header then header_options
          else unit_options(part)
          end
        end

        def merge_settings(values)
          return super unless defined?(@settings) && @settings

          values.each do |key, value|
            if UNITS.include?(key) && (current = @settings[key])
              (current['@append'] ||= []).push(value)
            else
              @settings[key] = value
            end
          end
        end
    end
  end
end
