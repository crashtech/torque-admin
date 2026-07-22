# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Column Node
    class ColumnNode < Node
      BLANK_CELL = -'<td></td>'.html_safe.freeze
      BLANK_HEADER = -'<th></th>'.html_safe.freeze
      APPENDABLE_PARTS = %i[col cell footer].to_set.freeze

      attr_reader :header, :column, :footer

      self.settings += %i[as sortable stretch] + APPENDABLE_PARTS.to_a

      def type
        (@rendering_type if defined?(@rendering_type)) || super
      end

      def sortable?
        fetch_setting(:sortable, @element&.default_sort_for(id))
      end

      def stretch?
        fetch_setting(:stretch, @element&.default_stretch_for(id))
      end

      def content
      end

      def render(outer: false)
        return content if outer

        options = sanitized_options
        render_header_part(options)
        render_column_part
        render_footer_part
      end

      def render_header_part(options)
        @header ||= begin
          options = options.reverse_merge(sortable: sortable?)
          render_part(:column_header, options, to: :headers, body: options.delete(:label))
        end
      end

      def render_column_part
        @column ||= render_part(:column_col, fetch_setting(:col, {}).reverse_merge(stretch: stretch?), to: :columns)
      end

      def render_footer_part
        return if defined?(@footer)

        options = fetch_setting(:footer)&.dup
        return if options.blank? && (!defined?(@element) || !@element.with_footer?)

        body = options&.delete(:content)
        @footer = render_part(:column_footer, options, to: :footers, body:)
      end

      protected

        def render_part(type, options, to:, body: nil)
          content = blank_part(type) if body.blank? && options.blank?
          content ||= begin
            @rendering_type = type
            handler, *settings = defined?(@element) ? @element.render_handler_for(self) : render_handler
            missing_handler! unless handler

            if handler.respond_to?(:call)
              handler.call(body, **options)
            else
              send(handler, nil, body, options, *settings)
            end
          ensure
            @rendering_type = nil
          end

          @element.append_content_for(to, content) if defined?(@element)
          content
        end

        def blank_part(type)
          (fetch_setting(:header, false) || type == :column_header) ? BLANK_HEADER : BLANK_CELL
        end

        def merge_settings(values)
          return super unless defined?(@settings)

          values.each do |key, value|
            if APPENDABLE_PARTS.include?(key) && (current = @settings[key])
              (current['@append'] ||= []).push(value)
            else
              @settings[key] = value
            end
          end
        end
    end
  end
end
