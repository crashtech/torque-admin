# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \UI Rendering Helpers
    class UiBuilder
      module Rendering
        def render_content_tag(tag_name, content = nil, options = {}, &)
          options = build_options(options) if options.is_a?(Array)
          content = view_context.capture(&) if block_given?

          combine_option('@content', options, content) if content.present?
          render_tag(tag_name, options, with_content: true)
        end

        def render_tag(tag_name, options = {}, with_content: false)
          options = build_options(options) if options.is_a?(Array)
          options = collapse_options(options)

          view_context.render_with_conditions(options) do
            left, *inner, right = options.delete('@content')&.values_at(*ContentHandler::PARTS)
            content = view_context.safe_join(inner.flatten) if with_content && inner.present?
            content = tag_builder.content_tag_string(tag_name, content, options)
            return content if left.nil? && right.nil?

            view_context.safe_join([*left, content, *right])
          end
        end
      end
    end
  end
end
